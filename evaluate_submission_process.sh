# evaluate_submission_process.sh $prj $pkg
#
#
### STATIC MAP BEGIN ###
# SLE-16.2  GNOME:Factory
# SLE-16.1  GNOME:STABLE:48
# SLE-16.0  GNOME:STABLE:48
# SLE15SP7 SUSE:SLE-15-SP7:Update GNOME:STABLE:45 Devel:Desktop:SLE-15-SP7
# SLE15SP6 SUSE:SLE-15-SP6:Update GNOME:STABLE:45 None
# SLE15SP5 SUSE:SLE-15-SP5:Update GNOME:STABLE:41 Devel:Desktop:SLE-15-SP5
# SLE15SP4 SUSE:SLE-15-SP4:Update GNOME:STABLE:41 None
# SLE15SP3 SUSE:SLE-15-SP3:Update GNOME:STABLE:3.34 Devel:Desktop:SLE-15-SP3
# SLE15SP2 SUSE:SLE-15-SP2:Update GNOME:STABLE:3.34 (?Devel:Desktop:SLE-15-SP2)
# SLE15SP1 SUSE:SLE-15-SP1:Update GNOME:STABLE:3.26 Devel:Desktop:SLE-15-SP1
# SLE15SP0 SUSE:SLE-15:Update     GNOME:STABLE:3.26 (?Devel:Desktop:SLE-15)
# SLE12SP5 SUSE:SLE-12-SP5:Update 
### STATIC MAP END ###

# TODO
# 1. notify already broken sync
# 2. use static database
#
# Check correctness of Devel and G:S
# 
# Move from Devel:Desktop:SLE-15 to G:S:3.26:
# NetworkManager-branding-SLE
# Packagekit-branding-SLE
# branding-SLE
# brise
# 
# Sync from Devel:Desktop:SLE-15 to G:S:3.26:
# appstream-glib (done)
# NetworkManager (done)
#
# Remove directly in Devel:Desktop:SLE-15 (either identical, or GNOME:STABLE:3.26 is incrementally ahead)
# accountsservice
# at-spi2-atk
# at-spi2-core
# atk
# atkmm1_6
# baobab
# bijiben
# cairo
# cairomm1_0
# cantarell-fonts
# caribou
# check
# 
# 
# NOT SURE
# PackageKit


# Release label and the project used to look up the package
release_projects=(
    "SLE-16.2|SUSE:SLFO:Main"
    "SLE-16.1|SUSE:SLFO:1.3"
    "SLE-16.0|SUSE:SLFO:1.2"
    "SLE-15-SP7|SUSE:SLE-15-SP7:Update"
    "SLE-15-SP6|SUSE:SLE-15-SP6:Update"
    "SLE-15-SP5|SUSE:SLE-15-SP5:Update"
    "SLE-15-SP4|SUSE:SLE-15-SP4:Update"
    "SLE-15-SP3|SUSE:SLE-15-SP3:Update"
    "SLE-15-SP2|SUSE:SLE-15-SP2:Update"
    "SLE-15-SP1|SUSE:SLE-15-SP1:Update"
    "SLE-15|SUSE:SLE-15:Update"
    "SLE-12-SP5|SUSE:SLE-12-SP5:Update"
)

# Probe the devel project for a target project
_probe_target_project() {
    local pkg="$1"
    local target_project="$2"

    devel_project=""

    case "$target_project" in
        SUSE:SLFO:1.2)
            _probe "$pkg" GNOME:STABLE:48
            ;;
        SUSE:SLFO:1.3)
            _probe "$pkg" GNOME:STABLE:48
            ;;
        SUSE:SLFO:Main)
            _probe "$pkg" GNOME:Factory
            ;;
        SUSE:SLE-15:Update|SUSE:SLE-15:GA)
            _probe "$pkg" GNOME:STABLE:3.26
            ;;
        SUSE:SLE-15-SP1:Update|SUSE:SLE-15-SP1:GA)
            _probe "$pkg" GNOME:STABLE:3.26 Devel:Desktop:SLE-15-SP1
            ;;
        SUSE:SLE-15-SP2:Update|SUSE:SLE-15-SP2:GA)
            _probe "$pkg" GNOME:STABLE:3.34
            ;;
        SUSE:SLE-15-SP3:Update|SUSE:SLE-15-SP3:GA)
            _probe "$pkg" GNOME:STABLE:3.34 Devel:Desktop:SLE-15-SP3
            ;;
        SUSE:SLE-15-SP4:Update|SUSE:SLE-15-SP4:GA)
            _probe "$pkg" GNOME:STABLE:41
            ;;
        SUSE:SLE-15-SP5:Update|SUSE:SLE-15-SP5:GA)
            _probe "$pkg" GNOME:STABLE:41 Devel:Desktop:SLE-15-SP5
            ;;
        SUSE:SLE-15-SP6:Update|SUSE:SLE-15-SP6:GA)
            _probe "$pkg" GNOME:STABLE:45
            ;;
        SUSE:SLE-15-SP7:Update|SUSE:SLE-15-SP7:GA)
            _probe "$pkg" GNOME:STABLE:45 Devel:Desktop:SLE-15-SP7
            ;;
        *)
            return 1
            ;;
    esac
}

# Resolve the package's current target project (following inheritance)
_resolve_target_project() {
    local prj="$1"
    local pkg="$2"

    osc meta pkg "$prj" "$pkg" 2>/dev/null | head -1 | grep -oP 'project="\K[^"]+'
}

# Compare the package between the devel project and the target project.
# Sets the global $diff_output; empty output means both sides are identical.
_compare_projects() {
    local pkg="$1"
    local devel_project="$2"
    local target_project="$3"
    local -a osc_args=()

    if [[ "$devel_project" == *Devel:Desktop* ]]; then
        osc_args=(-A https://api.suse.de)
    fi

    diff_output=$(osc "${osc_args[@]}" rdiff \
        "$devel_project" "$pkg" "$target_project" "$pkg" 2>&1)
}

# Probe the package status in one or two valid development projects
# (GNOME:STABLE, Devel:Desktop) to get the correct $devel_project

devel_project=""

_probe() {
    local pkg="$1"
    local proj_base="$2"
    local proj_devel="$3"

    # Reset the global variable
    devel_project=""

    if [ -z "$proj_devel" ]; then
        # Case 1: 1 project argument provided (e.g., GNOME:STABLE:3.26)
        if osc ls "$proj_base" "$pkg" &>/dev/null; then
            devel_project="$proj_base"
        fi
    else
        # Case 2: 2 project arguments provided 
        # Priority: Check the devel project first ($proj_devel), then the base project ($proj_base)
        if osc -A https://api.suse.de ls "$proj_devel" "$pkg" &>/dev/null; then
            devel_project="$proj_devel"
        elif osc ls "$proj_base" "$pkg" &>/dev/null; then
            devel_project="$proj_base"
        fi
    fi
}

# Show the target and devel projects for the given package
# Usage: show_devel_projects <package>

show_devel_projects() {
    local pkg="$1"
    local entry label base target sync
    local found=""

    for entry in "${release_projects[@]}"; do
        label=${entry%%|*}
        base=${entry#*|}

        target=$(_resolve_target_project "$base" "$pkg")
        [ -z "$target" ] && continue
        target=${target/GA/Update}

        _probe_target_project "$pkg" "$target" || continue
        if [ -n "$devel_project" ]; then
            _compare_projects "$pkg" "$devel_project" "$target"
            if [ -z "$diff_output" ]; then
                sync=Yes
            else
                sync=No
            fi
            echo "$label: $target -> $devel_project sync:$sync"
            found=1
        fi
    done

    if [ -z "$found" ]; then
        echo "Package $pkg not found in any devel project" >&2
    fi
}

usage() {
    echo "Usage: $0 <project> <package>" >&2
    echo "       $0 <package>" >&2
    exit 1
}

if [ $# -eq 1 ]; then
    pkg=$1
elif [ $# -eq 2 ]; then
    prj=$1
    pkg=$2

    # Normalize $prj input

    case "$prj" in
        SLE-16|SLE-16.0|SUSE:SLFO:1.2)
            prj="SUSE:SLFO:1.2"
            ;;
        SLE-16.1|SUSE:SLFO:1.3)
            prj="SUSE:SLFO:1.3"
            ;;
        SLE-16.2|SUSE:SLFO:Main)
            prj="SUSE:SLFO:Main"
            ;;
        SLE-15|SUSE:SLE-15:GA|SUSE:SLE-15:Update)
            prj="SUSE:SLE-15:Update"
            ;;
        SLE-15-SP1|SUSE:SLE-15-SP1:GA|SUSE:SLE-15-SP1:Update)
            prj="SUSE:SLE-15-SP1:Update"
            ;;
        SLE-15-SP2|SUSE:SLE-15-SP2:GA|SUSE:SLE-15-SP2:Update)
            prj="SUSE:SLE-15-SP2:Update"
            ;;
        SLE-15-SP3|SUSE:SLE-15-SP3:GA|SUSE:SLE-15-SP3:Update)
            prj="SUSE:SLE-15-SP3:Update"
            ;;
        SLE-15-SP4|SUSE:SLE-15-SP4:GA|SUSE:SLE-15-SP4:Update)
            prj="SUSE:SLE-15-SP4:Update"
            ;;
        SLE-15-SP5|SUSE:SLE-15-SP5:GA|SUSE:SLE-15-SP5:Update)
            prj="SUSE:SLE-15-SP5:Update"
            ;;
        SLE-15-SP6|SUSE:SLE-15-SP6:GA|SUSE:SLE-15-SP6:Update)
            prj="SUSE:SLE-15-SP6:Update"
            ;;
        SLE-15-SP7|SUSE:SLE-15-SP7:GA|SUSE:SLE-15-SP7:Update)
            prj="SUSE:SLE-15-SP7:Update"
            ;;
        *)
            echo "Unhandled project: $prj" >&2
            exit 1
            ;;
    esac
else
    usage
fi

if [ $# -eq 1 ]; then
    show_devel_projects "$pkg"
    exit 0
fi

# Infer a correct $devel_project from a $target_project

target_project=$(osc meta pkg $prj $pkg | head -1 | grep -oP 'project="\K[^"]+')
target_project=${target_project/GA/Update}

if ! _probe_target_project "$pkg" "$target_project"; then
    echo "Target project not found" >&2
    exit 1
fi

# Rough handling the package outside the devel projects

if test -z "$devel_project"; then
    echo "$pkg NOT in Devel:Desktop or GNOME:STABLE, direct submission to: $target_project";
    exit 0;
fi

# Output the process
if [[ "$target_project" == *SUSE:SLFO* ]]; then
    echo -e "$devel_project \n -> $target_project (git) $pkg\n"
else
    echo -e "$devel_project \n -> $target_project $pkg\n"
fi

# Compare $devel_project and $target_project, warning when there is a difference
_compare_projects "$pkg" "$devel_project" "$target_project"

# No difference, exit
[ -z "$diff_output" ] && exit 0

echo "Warning: Differences detected for package $pkg between $devel_project and $target_project."
read -r -p "Do you want to review the differences? (y/N): " choice

case "$choice" in
    [yY][eS]|[yY])
        # Huh, must use double quotes here so newlines and spacing are preserved
        echo "$diff_output" | less -R
        ;;
    *)
        echo "Skipping review."
        echo
        ;;
esac
