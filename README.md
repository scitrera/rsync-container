# rsync Container

A containerized version of rsync, designed for flexible synchronization tasks in various orchestration use cases.

## Overview

This container wraps the `rsync` utility, allowing it to be easily deployed and configured in containerized
environments. The default entrypoint is `/opt/rsync.sh`, which launches `rsync` with any arguments provided. This
container also includes optional features controlled by environment variables to support automated and recurring
synchronization workflows.

## Usage

To use the rsync container, run it with your desired `rsync` arguments. Here is a basic example:

```bash
podman run --rm ghcr.io/scitrera/rsync <your-rsync-args>
```

By default, the entrypoint script (`/opt/rsync.sh`) simply passes through the provided arguments to `rsync`.

## Configuration Options

### Environment Variables

The container behavior can be modified using the following environment variables:

- **`ALLOWED_RETURN_CODES`**: A comma-separated list of return codes that are considered successful. If the return code
  from `rsync` matches any in this list, the container will exit with status 0 (default: `"0,23"`).
    - `0` - Success, no errors
    - `23` - Partial transfer due to error (e.g., some files could not be transferred)

- **`RECURRING_WATCH`**: A colon-separated list of paths to watch for changes. If set, the `/opt/rsync.sh` script enters
  a loop that runs `inotifywait`, followed by `rsync`, and then `sleep`. This continues indefinitely until a SIGINT or
  SIGTERM signal is received.

- **`INOTIFY_EVENTS`**: A comma-separated list of events for `inotifywait` to listen for. Defaults
  to `"modify,create,delete,move"` if not specified. This variable is only relevant if `RECURRING_WATCH` is set. To
  disable `inotifywait` while continuing the loop, use the value `"-"`.

- **`SLEEP_DELAY`**: The number of seconds to sleep between loop iterations when `RECURRING_WATCH` is set. This can help
  manage the frequency of `rsync` runs, adding a delay between sync operations. Note that there is no default
  for `SLEEP_DELAY` and there will be no delay if not set.

## Example Commands

### Basic Sync Operation

To perform a simple file synchronization with `rsync` using this container:

```bash
docker run --rm \
  -v /source/path:/source:ro \
  -v /destination/path:/destination \
  ghcr.io/scitrera/rsync --itemize-changes /source/* /destination/
```

### Recurring Sync with File Monitoring

To run a recurring sync operation that reacts to changes in the `/source` directory:

```bash
docker run --rm \
  -v /source/path:/source:ro \
  -v /destination/path:/destination \
  -e RECURRING_WATCH="/source" \
  -e SLEEP_DELAY="5" \
  ghcr.io/scitrera/rsync --itemize-changes /source/* /destination/
```

In this example, the container will use `inotifywait` to monitor `/source` for modifications, and synchronize changes
to `/destination` every time an event occurs. Glob syntax will be expanded by the shell (which is still OK in the
recurring sync scenario because the glob expression is re-evaluated at each `rsync` run).

## Signals and Graceful Shutdown

The container can be stopped gracefully by sending either a SIGINT or SIGTERM signal. When using `RECURRING_WATCH`,
these signals ensure that the current `rsync` operation completes before the container exits.

## Return Codes

The default behavior is to consider `rsync` return codes `0` and `23` as successful runs. You can modify this by
setting `ALLOWED_RETURN_CODES` to include additional (or fewer) return codes based on your requirements.

## Container Registry

The container is available at the following registry:

- **GitHub Container Registry**:
  [ghcr.io/scitrera/rsync](https://github.com/scitrera/rsync-container/pkgs/container/rsync)

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request if you find a bug or have a feature
request.

## License

This project is licensed under the 3-clause BSD License.

## Support

If you encounter any issues or need help, please open an issue on
the [GitHub repository](https://github.com/scitrera/rsync-container).

