SVerif: ECCC-MRD-RPN Statistical verification package

# At CMC

git clone -b 5.3 git@gitlab.science.gc.ca:MIG/sverif.git

# Environment

Code-tools are loaded through the `.eccc_setup_intel` file.

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

librmn is loaded through the `.eccc_setup_intel` file.

# Running Sverif
 - https://wiki.cmc.ec.gc.ca/wiki/Sverif
 - use -b 5 only to test the mechanism of sverif
 - use -b 1000 to compare generated image (png) between versions of sverif
 - run to run results are not bit-reproducible as random generator is used

```
. r.load.dot [path where package is installed]
```

Or to test locally, the path to find the binaries:

```
export PATH=[path of where you cloned sverif]/build/install/bin:$PATH
```

(intel compiler code-tools must be loaded)

```
cd [path of where your files to verify]

sverif_prep  -p 24 -b 5 -s $PWD prgdm2021120200_024 prgdm2021120201_024 prgdm2021120202_024
sverif_eval -p 24  -s $PWD prgdm2021120200_024 prgdm2021120201_024 prgdm2021120202_024
```
