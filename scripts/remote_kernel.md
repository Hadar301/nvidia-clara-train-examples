# Connecting to Remote Jupyter Kernel from Local IDE

This guide explains how to connect your local IDE (VS Code or other) to the Jupyter server running in your RHOAI workbench pod for remote code execution.

## ⚠️ Important Limitations

**File System Location**: When you connect to the remote kernel, **all file operations still happen on the workbench's PVC**, not your local filesystem.

- ✅ **Good for**: Running notebooks remotely with GPU acceleration while editing locally
- ❌ **Not recommended for**: General development workflow where you need local file access
- ⚠️ **Be aware**: Files you read/write in notebooks will be on the remote PVC, not your local machine

**Recommended workflow**: Use the RHOAI web interface for most work. Only use remote kernel connection if you specifically need local IDE features while executing remotely.

## Prerequisites

- Clara Train workbench running in RHOAI
- Custom Clara Train image with token authentication (see [Containerfile](../clara-train-prerequisites/Containerfile))
- `oc` CLI authenticated to your OpenShift cluster
- VS Code with Jupyter extension installed (or other IDE with Jupyter support)

## Connection Setup

### Step 1: Port Forward to Workbench

In your local terminal, start a port forward to the workbench pod:

```bash
oc port-forward <workbench-pod-name> 8888:8888
```

**Example**:
```bash
oc port-forward clara-workbench-0 8888:8888
```

Keep this terminal window open - the port forward must stay running for the connection to work.

### Step 2: Get Connection Details

**Jupyter Server URL**:
```
http://localhost:8888/notebook/<namespace>/<workbench-name>
```

**Token**:
```
clara-train-2026
```
(Default token set in the custom Containerfile - can be changed via `NB_TOKEN` environment variable)

**Example**:
```
URL: http://localhost:8888/notebook/hacohen-clara/clara-workbench
Token: clara-train-2026
```

### Step 3: Connect from VS Code

1. **Open a Notebook**
   - Open any `.ipynb` file in your local workspace
   - Example: `clara-train-examples/PyTorch/NoteBooks/GettingStarted/GettingStarted.ipynb`

2. **Select Kernel**
   - Click "Select Kernel" in the top right corner of the notebook
   - Choose "Existing Jupyter Server"
   - Select "Enter the URL of the running Jupyter server"

3. **Enter Server Details**
   - URL: `http://localhost:8888/notebook/<namespace>/<workbench-name>`
   - When prompted for token, enter: `clara-train-2026`

4. **Choose Kernel**
   - Select the Python kernel from the remote server
   - Should show Python 3.8 with PyTorch/MONAI environment

## How It Works

```
┌─────────────────┐         Port Forward        ┌──────────────────┐
│  Local VS Code  │◄──────────8888:8888─────────►│  Workbench Pod   │
│                 │                               │                  │
│  Edit notebooks │         SSH Tunnel            │  Execute code    │
│  locally        │         via oc CLI            │  with GPU        │
│                 │                               │                  │
│  ❌ Local files │                               │  ✅ Remote files │
└─────────────────┘                               └──────────────────┘
                                                           │
                                                           ▼
                                                  ┌──────────────────┐
                                                  │   Workbench PVC  │
                                                  │   (Remote files) │
                                                  └──────────────────┘
```

**Key Points**:
- **Code editing**: Happens locally in your IDE
- **Code execution**: Runs remotely in the workbench pod with GPU access
- **File I/O**: All file operations happen on the remote PVC, **NOT** your local filesystem
- **Data**: Stored in the workbench PVC at `/opt/app-root/src`

## File System Behavior

### What Happens When You Run Code

When you execute notebook cells:

```python
# This reads from REMOTE PVC, not your local machine
data = pd.read_csv("/opt/app-root/src/data/dataset.csv")

# This writes to REMOTE PVC, not your local machine
model.save("/opt/app-root/src/models/my_model.pt")

# This lists REMOTE directories, not local
import os
print(os.listdir("."))  # Shows remote workbench files
```

### To Access Local Files

You **cannot** directly access local files from remote kernel. You must:

1. **Upload to workbench** using `oc cp`:
   ```bash
   oc cp /local/path/file.csv <workbench-pod>:/opt/app-root/src/data/file.csv
   ```

2. **Use Jupyter file upload** in the web interface

3. **Clone from Git** directly in the workbench

## Use Cases

### ✅ Good Use Cases

1. **GPU-accelerated notebook development**
   - Write code locally with IDE features (autocomplete, linting, etc.)
   - Execute remotely with GPU acceleration
   - All training data already on remote PVC

2. **Collaborative editing**
   - Edit notebooks locally while sharing remote execution environment
   - Multiple users can connect to same remote server

3. **Using local IDE features**
   - Better code navigation
   - Integrated debugging
   - Custom extensions and themes

### ❌ Not Recommended

1. **Working with local datasets**
   - Files on your machine aren't accessible
   - Must upload everything to remote PVC first

2. **Frequent file operations**
   - Every file read/write goes through remote connection
   - Network latency affects performance

3. **Offline development**
   - Requires active connection to workbench
   - Port forward must stay running

## Troubleshooting

### Connection Failure

**Symptom**: VS Code shows "Connection failure" when trying to connect

**Solution**:
1. Verify port forward is running:
   ```bash
   ps aux | grep "port-forward"
   ```

2. Test connection manually:
   ```bash
   curl http://localhost:8888/notebook/<namespace>/<workbench-name>/api/status
   ```

3. Ensure you're using the full URL with base path (not just `http://localhost:8888`)

### Wrong File Paths

**Symptom**: `FileNotFoundError` even though file exists locally

**Cause**: Remote kernel looks for files on remote PVC, not local machine

**Solution**:
- Upload files to workbench first using `oc cp`
- Or use full remote paths: `/opt/app-root/src/...`

### Port Forward Drops

**Symptom**: Connection lost during work

**Solution**:
1. Restart port forward:
   ```bash
   oc port-forward <workbench-pod> 8888:8888
   ```

2. Reconnect in VS Code (may need to restart kernel)

3. For more stable connection, run port forward in background:
   ```bash
   oc port-forward <workbench-pod> 8888:8888 > /tmp/pf.log 2>&1 &
   ```

## Security Considerations

- **Token authentication**: Default token is `clara-train-2026` - change for production
- **Port forward**: Only accessible from localhost (secure by default)
- **OAuth bypass**: Port forward bypasses OAuth proxy (requires `oc` authentication instead)
- **Network traffic**: All communication goes through encrypted OpenShift connection

## Customizing the Token

To use a different token:

1. **Modify Containerfile**:
   ```dockerfile
   CMD [...--NotebookApp.token=${NB_TOKEN:-your-custom-token}...]
   ```

2. **Or set environment variable** in workbench configuration:
   ```yaml
   env:
     - name: NB_TOKEN
       value: "your-secure-token"
   ```

3. Rebuild and redeploy the image

## Alternative: Use RHOAI Web Interface

For most workflows, using the RHOAI web interface is simpler and more reliable:

**Advantages**:
- Direct file access to PVC
- No port forwarding needed
- OAuth authentication handled automatically
- No local/remote file system confusion
- Built-in terminal access

**Access**: Click "Open" on your workbench in the RHOAI dashboard

## Additional Resources

- [Getting Started Guide](../getting_started.md) - Running notebooks via RHOAI web interface
- [Containerfile](../clara-train-prerequisites/Containerfile) - Custom image configuration
- [Clara Train Prerequisites](../clara-train-prerequisites/README.md) - Installation guide

## Summary

Remote kernel connection allows you to edit notebooks locally while executing on remote GPU, but **all file operations happen on the remote PVC**. This makes it less suitable for general development and more suited for specific use cases where you need local IDE features while working with data already on the remote system.

**For most Clara Train workflows, using the RHOAI web interface is recommended.**
