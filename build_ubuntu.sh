rclone_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$rclone_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <rclone_version> <build_version> [architecture]"
    echo "Example: $0 1.75.0 1 arm64"
    echo "Example: $0 1.75.0 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, armhf, all"
    exit 1
fi

# Function to map Ubuntu architecture to rclone release name
# Upstream ships linux binaries for: 386, amd64, arm, arm-v6, arm-v7, arm64,
# mips, mipsle. There is no riscv64 build, and Ubuntu no longer has i386 as a
# release architecture, so neither is claimed here.
get_rclone_release() {
    local arch=$1
    case "$arch" in
        "amd64")
            echo "rclone-v${rclone_VERSION}-linux-amd64"
            ;;
        "arm64")
            echo "rclone-v${rclone_VERSION}-linux-arm64"
            ;;
        "armhf")
            echo "rclone-v${rclone_VERSION}-linux-arm-v7"
            ;;
        *)
            echo ""
            ;;
    esac
}

# rclone does not ship completion scripts in its release archives, but the
# binary can emit them (`rclone completion bash|zsh|fish -`). The generated
# scripts are pure shell and identical on every architecture, so we generate
# them once per build run and reuse them for every arch/suite. When the target
# architecture's binary cannot be executed on this host we fall back to the
# amd64 build purely to emit the scripts.
ensure_completions() {
    local binary=$1

    if [ -f completions/rclone.bash ] && [ -f completions/_rclone ] && [ -f completions/rclone.fish ]; then
        return 0
    fi

    mkdir -p completions

    local generator="$binary"
    local scratch=""
    if ! "$generator" version >/dev/null 2>&1; then
        echo "  Target binary is not executable on this host; fetching amd64 build to generate completions"
        scratch=".completion-gen"
        rm -rf "$scratch"
        mkdir -p "$scratch"
        if ! wget -q "https://github.com/rclone/rclone/releases/download/v${rclone_VERSION}/rclone-v${rclone_VERSION}-linux-amd64.zip" -O "$scratch/rclone.zip"; then
            echo "❌ Failed to download the amd64 build needed to generate completions"
            rm -rf "$scratch"
            return 1
        fi
        unzip -q -o "$scratch/rclone.zip" -d "$scratch"
        chmod 755 "$scratch/rclone-v${rclone_VERSION}-linux-amd64/rclone"
        generator="$scratch/rclone-v${rclone_VERSION}-linux-amd64/rclone"
    fi

    "$generator" completion bash completions/rclone.bash &&
    "$generator" completion zsh  completions/_rclone &&
    "$generator" completion fish completions/rclone.fish
    local rc=$?

    [ -n "$scratch" ] && rm -rf "$scratch"
    [ $rc -eq 0 ] || return 1

    echo "  Generated bash/zsh/fish completions"
    return 0
}

# Function to build for a specific architecture
build_architecture() {
    local build_arch=$1
    local rclone_release

    rclone_release=$(get_rclone_release "$build_arch")
    if [ -z "$rclone_release" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, arm64, armhf"
        return 1
    fi

    echo "Building for architecture: $build_arch using $rclone_release"

    # Clean up any previous builds for this architecture
    rm -rf "$rclone_release" || true
    rm -f "${rclone_release}.zip" || true

    # Download and extract the rclone binary for this architecture
    if ! wget "https://github.com/rclone/rclone/releases/download/v${rclone_VERSION}/${rclone_release}.zip"; then
        echo "❌ Failed to download rclone binary for $build_arch"
        return 1
    fi

    # rclone ships zip archives containing a single <release>/ directory
    if ! unzip -q -o "${rclone_release}.zip"; then
        echo "❌ Failed to extract rclone binary for $build_arch"
        return 1
    fi

    rm -f "${rclone_release}.zip"
    chmod 755 "${rclone_release}/rclone"

    if ! ensure_completions "${rclone_release}/rclone"; then
        echo "❌ Failed to generate shell completions"
        return 1
    fi

    # Build packages for appropriate Ubuntu distributions
    declare -a arr=("jammy" "noble" "questing" "resolute")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$rclone_VERSION-${BUILD_VERSION}~${dist}_${build_arch}_ubu"
        echo "  Building $FULL_VERSION"

        if ! docker build . -f Dockerfile.ubu -t "rclone-ubuntu-$dist-$build_arch" \
            --build-arg UBUNTU_DIST="$dist" \
            --build-arg rclone_VERSION="$rclone_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch" \
            --build-arg RCLONE_RELEASE="$rclone_release"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi

        id="$(docker create "rclone-ubuntu-$dist-$build_arch")"
        if ! docker cp "$id:/rclone_$FULL_VERSION.deb" - > "./rclone_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi

        if ! tar -xf "./rclone_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done

    # Clean up extracted directory
    rm -rf "$rclone_release" || true

    echo "✅ Successfully built for $build_arch"
    return 0
}

# Main build logic
if [ "$ARCH" = "all" ]; then
    echo "🚀 Building rclone $rclone_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""

    # All supported architectures
    # Ubuntu dropped i386 as a release architecture
    ARCHITECTURES=("amd64" "arm64" "armhf")

    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="

        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi

        echo ""
    done

    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la rclone_*.deb
else
    # Build for single architecture
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi
