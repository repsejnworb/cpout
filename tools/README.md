# Default (patch bump): vX.Y.(Z+1)
tools/release.sh

# Minor bump, custom notes
tools/release.sh -b minor -m "Add completion & README polish"

# Just build the artifact (no tag or release)
tools/release.sh --build-only