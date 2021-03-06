Dell XPS 9650 Kernel Builder for Fedora
=======================================

This script builds and installs the current stable version of the kernel with
patches and config for the Dell XPS 9650.

Kernel Changes
--------------

- Add `CONFIG_ACPI_REV_OVERRIDE_POSSIBLE=y` option. See 
https://cateee.net/lkddb/web-lkddb/ACPI_REV_OVERRIDE_POSSIBLE.html for details
on this kernel option. This is required to allow the kernel to properly
control the discrete graphics adapters power status. It helps prevent the lock
on sleep issue. The kernel boot flag `acpi_rev_override=1` should be set to
take advantage of this option.


Usage
-----

```bash
./build.sh build_id
```

Where `build_id` is a name for your build.


Todo
----

- Add error handling
