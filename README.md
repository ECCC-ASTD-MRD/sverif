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

Source the right file from the `ECCI_ENV` variable, depending on the desired
architecture.  This will load the specified compiler, set the
`ECCI_DATA_DIR` variable for the test datasets, and set the
`EC_CMAKE_MODULE_PATH` variable for the `cmake_rpn` modules.

- Example for PPP5:

```
. $ECCI_ENV/latest/ppp5/inteloneapi-2022.1.2.sh
```

- Example for CMC network and gnu 11.4.0:

```
. $ECCI_ENV/latest/ubuntu-22.04-amd-64/gnu.sh
```

Since the default version of CMake available on ECCC systems is probably too
old, you need to load a version newer than 3.20.  For example: `. ssmuse-sh
-d main/opt/cmake/cmake-3.21.1`.

Load the latest stable version of librmn.

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
- librmn with shared libraries (https://github.com/ECCC-ASTD-MRD/librmn/)

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
 - https://wiki.cmc.ec.gc.ca/wiki/Sverif
 - use -b 5 only to test the mechanism of sverif
 - use -b 1000 to compare generated image (png) between versions of sverif
 - run to run results are not bit-reproducible as random generator is used

```
sverif_prep -p 24 -b 5 -s $PWD prgdm2021120200_024 prgdm2021120201_024 prgdm2021120202_024
sverif_eval -p 24  -s $PWD prgdm2021120200_024 prgdm2021120201_024 prgdm2021120202_024
```
