SVerif: ECCC-MRD-RPN Statistical verification package

# At CMC

- CMake 3.20+
- librmn

# Environment


# Build and install

```
. ./.eccc_setup_intel
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$PWD/install
make -j 4
make package
```

make package will prepare an SSM package.

# Dependencies

modelutils is included as a subtree and can be updated in the same way as in
GEM (see GEM wiki for more information).

librmn is loaded through the `.eccc_setup_intel`.
