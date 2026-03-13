#!/bin/bash
# Lilith Linux Build State Tracker
# Tracks build progress and enables resume capability

set -e

BUILD_STATE_FILE="/home/aegon/Lilith-Build/build-state.json"
LOG_DIR="/home/aegon/Lilith-Build/build-logs"

# Initialize build state
init_state() {
    cat > "$BUILD_STATE_FILE" << 'EOF'
{
  "version": "1.0",
  "last_updated": null,
  "current_phase": null,
  "phases": {
    "base_setup": {
      "status": "pending",
      "started": null,
      "completed": null,
      "log": null
    },
    "cosmic_build": {
      "status": "pending",
      "started": null,
      "completed": null,
      "log": null,
      "components": {}
    },
    "lilith_apps": {
      "status": "pending",
      "started": null,
      "completed": null,
      "log": null,
      "apps": {}
    },
    "rust_alternatives": {
      "status": "pending",
      "started": null,
      "completed": null,
      "log": null
    },
    "repo_setup": {
      "status": "pending",
      "started": null,
      "completed": null,
      "log": null
    },
    "iso_creation": {
      "status": "pending",
      "started": null,
      "completed": null,
      "log": null
    }
  },
  "disk_space": {
    "root": null,
    "home": null,
    "flash": null
  },
  "errors": [],
  "warnings": []
}
EOF
    mkdir -p "$LOG_DIR"
    echo "Build state initialized at $BUILD_STATE_FILE"
}

# Update phase status
update_phase() {
    local phase="$1"
    local status="$2"
    local component="${3:-}"
    local log_file="${4:-}"
    
    if [ ! -f "$BUILD_STATE_FILE" ]; then
        init_state
    fi
    
    # Use python3 for JSON manipulation (more reliable)
    python3 << PYEOF
import json
import sys
from datetime import datetime

with open("$BUILD_STATE_FILE", "r") as f:
    state = json.load(f)

state["last_updated"] = datetime.now().isoformat()

if "$component" != "":
    # Update component within a phase
    if "$phase" in state["phases"] and "components" in state["phases"]["$phase"]:
        state["phases"]["$phase"]["components"]["$component"] = {
            "status": "$status",
            "updated": datetime.now().isoformat()
        }
    elif "$phase" in state["phases"] and "apps" in state["phases"]["$phase"]:
        state["phases"]["$phase"]["apps"]["$component"] = {
            "status": "$status",
            "updated": datetime.now().isoformat()
        }
else:
    # Update entire phase
    if "$phase" in state["phases"]:
        state["phases"]["$phase"]["status"] = "$status"
        if "$status" == "in_progress":
            state["phases"]["$phase"]["started"] = datetime.now().isoformat()
            state["current_phase"] = "$phase"
        elif "$status" in ["completed", "failed"]:
            state["phases"]["$phase"]["completed"] = datetime.now().isoformat()
            state["phases"]["$phase"]["log"] = "$log_file" if "$log_file" else None

with open("$BUILD_STATE_FILE", "w") as f:
    json.dump(state, f, indent=2)
PYEOF
    
    echo "Phase '$phase' updated to '$status'"
}

# Get current state
show_state() {
    if [ ! -f "$BUILD_STATE_FILE" ]; then
        echo "No build state found. Run init first."
        return 1
    fi
    
    python3 -m json.tool "$BUILD_STATE_FILE" || cat "$BUILD_STATE_FILE"
}

# Get next pending phase
get_next_phase() {
    if [ ! -f "$BUILD_STATE_FILE" ]; then
        echo "base_setup"
        return
    fi
    
    python3 << 'PYEOF'
import json
with open("$BUILD_STATE_FILE", "r") as f:
    state = json.load(f)

phases = state.get("phases", {})
for name, data in phases.items():
    status = data.get("status", "pending")
    if status in ["pending", "in_progress", "failed"]:
        print(name)
        break
PYEOF
}

# Add error
add_error() {
    local error_msg="$1"
    
    python3 << PYEOF
import json
from datetime import datetime

with open("$BUILD_STATE_FILE", "r") as f:
    state = json.load(f)

state["errors"].append({
    "time": datetime.now().isoformat(),
    "message": "$error_msg"
})

with open("$BUILD_STATE_FILE", "w") as f:
    json.dump(state, f, indent=2)
PYEOF
    
    echo "Error added: $error_msg"
}

# Update disk space
update_disk_space() {
    python3 << PYEOF
import json
import subprocess

with open("$BUILD_STATE_FILE", "r") as f:
    state = json.load(f)

# Get disk space
result = subprocess.run(["df", "-h", "/"], capture_output=True, text=True)
lines = result.stdout.strip().split("\n")
if len(lines) > 1:
    parts = lines[1].split()
    if len(parts) >= 4:
        state["disk_space"]["root"] = {
            "total": parts[1],
            "used": parts[2],
            "available": parts[3],
            "percent": parts[4]
        }

# Get home space
result = subprocess.run(["df", "-h", "/home"], capture_output=True, text=True)
lines = result.stdout.strip().split("\n")
if len(lines) > 1:
    parts = lines[1].split()
    if len(parts) >= 4:
        state["disk_space"]["home"] = {
            "total": parts[1],
            "used": parts[2],
            "available": parts[3],
            "percent": parts[4]
        }

with open("$BUILD_STATE_FILE", "w") as f:
    json.dump(state, f, indent=2)
PYEOF
    
    echo "Disk space updated"
}

# Main
case "${1:-}" in
    init)
        init_state
        ;;
    update)
        update_phase "$2" "$3" "$4" "$5"
        ;;
    show)
        show_state
        ;;
    next)
        get_next_phase
        ;;
    error)
        add_error "$2"
        ;;
    disk)
        update_disk_space
        ;;
    *)
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  init          - Initialize build state"
        echo "  update <phase> <status> [component] [log] - Update phase status"
        echo "  show          - Show current state"
        echo "  next          - Get next pending phase"
        echo "  error <msg>   - Add error message"
        echo "  disk          - Update disk space info"
        ;;
esac
