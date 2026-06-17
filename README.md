# Description

`ECCC-MRD-RPN Statistical verification package`

* The statistical verification package (sverif) is designed to allow model developers to assess the impact of small changes with a single model integration.  This is useful when modifications are expected to modify the bitpattern of the results, but not the meteorology.  The package provides tools to allow for the construction of benchmark data, and to compare subsequent integrations with the expected results.

* Although the statistical verification package was developed for the comparison of a model integration against the range of expected results, it is based on concepts developed for general comparison of 2D fields.  It may therefore be useful for other applications not anticipated by the developers of the package.

* The [user's Guide](doc/userguide.md) is a way for users to quickly learn how to use the statistical verification package.

* The [technical documentation](doc/techdoc.md) about the statistical verification package is designed for developers who intend to modify the source code of the package.

* See also [sverif-presentation-2012.ppt](doc/sverif-presentation-2012.ppt)

# Compilation

## At CMC

### Build dependencies

- CMake 3.20+
- librmn

### Environment

You can use the setup file for Intel:  
```
. ./.eccc_setup_intel
```

Or load the right environment, depending on the architecture you need.  This
will load the specified compiler and its parameters, and set the
`EC_CMAKE_MODULE_PATH` variable for the `cmake_rpn` modules.

- Example for ppp7/sc7 and icelake specific architecture:

```
. r.load.dot mrd/rpn/code-tools/latest/env/rhel-9-graniterapids-64@inteloneapi-2025.1.0
```

- Example for generic architecture on ppp7/sc7

```
. r.load.dot mrd/rpn/code-tools/latest/env/rhel-9-amd64-64@inteloneapi-2025.1.0
```

- Example for GNU on any architecture:

```
. r.load.dot mrd/rpn/code-tools/latest/env/gnu
```

Load the latest alpha version of librmn.

### Build and install

```
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${your_choice}
make -j 4
make install
```

### Preparing package

```
make package
```

## Outside CMC (external users)

### Build dependencies

- CMake 3.20+
- librmn alpha branch with shared libraries (https://github.com/ECCC-ASTD-MRD/librmn/tree/alpha)

`cmake_rpn` is included as a git submodule.  Please clone with the
`--recursive` option or run `git submodule update --init --recursive` in the
git repo after having cloned.

### Build and install

```
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${your_choice} -Drmn_ROOT=${librmn_install_path}
make -j 4
make install
```

# Running Sverif
 - Internal documentation: https://wiki.cmc.ec.gc.ca/wiki/Sverif
 - use -b 5 only to test the mechanism of sverif
 - use -b 1000 to compare generated image (png) between versions of sverif
 - run to run results are not bit-reproducible as random generator is used

```
sverif_prep -p 24 -b 5 -s $PWD prgdm2021120200_024 prgdm2021120201_024 prgdm2021120202_024
sverif_eval -p 24  -s $PWD prgdm2021120200_024 prgdm2021120201_024 prgdm2021120202_024
```
