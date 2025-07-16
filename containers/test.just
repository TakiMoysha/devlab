[group: "dev"]
podman-rund-dokku:
  echo "TODO"
  # podman run 

# https://podman-desktop.io/docs/podman/gpu
[group: "smoke"]
podman-test-nvidia:
  podman run --rm \
    --device nvidia.com/gpu=all \
    nvidia/cuda:12.9.1-base-ubuntu20.04 \
    nvidia-smi


# ex: just test::pytest
pytest:
	#!/usr/bin/env -S uv run --script
	print("run with shebang")
