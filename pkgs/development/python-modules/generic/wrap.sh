wrapPythonPrograms() {
    wrapPythonProgramsIn $out "$out $pythonPath"
}

wrapPythonProgramsIn() {
    local dir="$1"
    local pythonPath="$2"
    local python="$(type -p python)"
    local i

    declare -A pythonPathsSeen=()
    program_PYTHONPATH=
    program_PATH=
    for i in $pythonPath; do
        _addToPythonPath $i
    done

    program_PYTHONPATH='$(
        # activate site if installed
        bindir=$(dirname "$0")
        pysite="$bindir/pysite"
        relpath=$(test -x "$pysite" && "$pysite" path)
        echo -n ${relpath:+"$relpath":}
)'"$program_PYTHONPATH"

    for i in $(find "$dir" -type f -perm +0100); do

        # Rewrite "#! .../env python" to "#! /nix/store/.../python".
        if head -n1 "$i" | grep -q '#!.*/env.*python'; then
            sed -i "$i" -e "1 s^.*/env[ ]*python^#! $python^"
        fi
        
        # PYTHONPATH is suffixed, PATH is prefixed. Reasoning:
        # PATH is set in the environment and our packages' bin need to
        # be chosen over the default PATH. PYTHONPATH is usually not
        # set, so we can use it to override the modules chosen at
        # install time. If we would want the same for PATH we could
        # introduce PATH_OVERWRITE or similar.
        if head -n1 "$i" | grep -q /python; then
            echo "wrapping \`$i'..."
            wrapProgram "$i" \
                --suffix PYTHONPATH ":" "$program_PYTHONPATH" \
                --prefix PATH ":" $program_PATH
        fi
    done
}

_addToPythonPath() {
    local dir="$1"
    if [ -n "${pythonPathsSeen[$dir]}" ]; then return; fi
    pythonPathsSeen[$dir]=1
    addToSearchPath program_PYTHONPATH $dir/lib/@libPrefix@/site-packages
    addToSearchPath program_PATH $dir/bin
    local prop="$dir/nix-support/propagated-build-native-inputs"
    if [ -e $prop ]; then
        local i
        for i in $(cat $prop); do
            _addToPythonPath $i
        done
    fi
}
