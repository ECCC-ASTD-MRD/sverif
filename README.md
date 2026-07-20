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
cmake .. -DCMAKE_INSTALL_PREFIX=${your_install_choice}
make -j 4
make install
```

If testing locally, set the PATH environment to find bin, scripts
And make sure you are running on a backend node with lots of cpus

### Export variables to test locally

```
cd [path of cloned repo]
export PATH=${PWD}/scripts:${your_install_choice}/bin:${PATH}
mkdir work
cd work
mkdir STATS
Look at Running Sverif below
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
 - -n for name of variable
 - -v for verbose
 - -l for level in mb
 - -p for prog in hours
 - -t for number of threads to use (100 is much faster than 8)
 - run to run results are not bit-reproducible as random generator is used

```
sverif_prep -p 24 -b 5 -s $PWD prgdm2021120200_024 prgdm2021120201_024 prgdm2021120202_024
sverif_eval -p 24  -s $PWD prgdm2021120200_024 prgdm2021120201_024 prgdm2021120202_024
sverif_prep -n TT -l 850 -b 1000 -p 6 -t 100 -s [work_path]/STATS [data_path]/2022040500_*
--> to test only sverif_prep.Abs, must uncomment lines in sverif_prep.F90 to obtain the temporary file [ctrl_filename]
sverif_prep.Abs TT 850 6 [ctrl_filename] [work_path]/STATS/
sverif_eval -n TT -l 850 -p 6 -s [work_path]/STATS [data_path]/2022040500_*
sverif_eval.Abs  TT 850 6 2022040500_169x57 [work_path]/STATS
```
