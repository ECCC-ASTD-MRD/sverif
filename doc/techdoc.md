# Technical Documentation for the Statistical Verification Package
This Technical Documentation is intended to help developers work with the Statistical Verification Package (SVP).  Information about the use of the SVP is available in the [User's Guide](userguide.md).

* [Layout of the Package](#layout-of-the-package)
   * [Interface Layer](#interface-layer)
   * [Statistical Evaluation and Plotting](#statistical-evaluation-and-plotting)
   * [Calculation Backend](#calculation-backend)
* [Files Generated by the SVP](#files-generated-by-the-svp)
   * [Temporary Files](#temporary-files)
   * [Statistics Files](#statistics-files)
* [The sverif_fname.Abs Utility](#the-sverif_fnameabs-utility)
* [Environment Variables](#environment-variables)

# Layout of the Package
The SVP comprises three layers that interact with each other in both the precalculation [sverif_prep](userguide#the-sverif_prep-utility) and the evaluation [sverif_eval](userguide#the-sverif_eval-utility) utilities.  Depending on the needs of the user, some of the lower-level layers can be accessed directly if sufficient information is given to the application.

## Interface Layer
The interface layer is written in [http://www.python.org/ python], primarily to implement a clean interface for users with the `optparse` module.  Checks for required arguments and bulk error checks (e.g. for file existance) are also performed at this layer in order both to take advantange of python's error handling capacity and to quickly provide users information about erroneous requests.  The interface layer for [sverif_prep](userguide#the-sverif_prep-utility) also provides a [temporary file](#temporary-files) using the `tempfile` tempfile package, to the lower layers of the SVP.

## Statistical Evaluation and Plotting
The implementation of the statistical techniques employed by the SVP is almost entirely accomplished in this layer, which is written in the [[http://www.r-project.org/ R]] programming languate.  This includes the generation of sampling information for the boostrapping operation and the determination of confidence intervals for the test statistics.  Information from the [interface layer](#interface-layer) is passed as a set of static arguments to the R scripting to simplify `CommandArgs()` parsing within this element of the SVP.

In [sverif_prep](userguide#the-sverif_prep-utility), the named temporary file created by the [interface layer](#interface-layer) is filled with sampling information for the [calculation backend](#calculation-backend), and an [auxiliary file](#auxiliary-file) containing information about inflation and the confidence intervals is generated.

In [sverif_eval](userguide#the-sverif_eval-utility), test statistics computed by the [calculation backend](#calculation-backend) are combined with the precomputed [statstics files](#statstics-files) to create the plot that is the final output of the SVP.

## Calculation Backend
This component of the SVP is written in Fortran, and performs almost all of the calculations involved in the SVP.  The majority of the code in this layer consists of FST file-handling and calculation of the test statistics.  An externally-accessible element of this layer [sverif_fname.Abs](#the-sverif_fnameabs-utility) is also responsible for managing the names of the [statstics files](#statstics-files) employed by the SVP.

Since the majority of time associated with execution of the SVP utilities is spent in this base layer of the package, the calculation backend for [sverif_prep](userguide#the-sverif_prep-utility) has been parallelized using [http://openmp.org/wp/ OpenMP].  The design of the code lends itself to this pardigm since each member of the bootstrap is entirely independent and can be executed in an embarassingly parallel fashion.  The programs in this layer are not memory-intensive, and thus appear to scale quite well.

# Files Generated by the SVP
Since the SVP is implemented in three [[#Layout of the Package|layers]], there is an obvious need for interprocess communication.  This is accomplished using a mix of command line arguments (static below the [interface layer](#interface-layer)) and files.  Since the bootstrapping involved in the precalculation procedure is compultationally costly, there is also a set of files that allows for the distilling and storing of information that is fixed for a given set of "control" grids.

## Temporary Files
The only temporary file employed by the SVP is created in the [interface layer](#interface-layer) of the [sverif_prep](userguide#the-sverif_prep-utility), and filled by the [[statistics evaluation](#statistical-valuation-and-plotting) layer (`prep.R`) to store data file name and bootstrap information (including resample sets) for the [calculation backend](#calculation-backend) (`sverif_prep.Abs`).  The [sverif_prep](userguide#the-sverif_prep-utility) utility creates a named temporary file using python's `tempfile` package, and takes care of garbage collection before the python program ends.  This file therefore only exists during the exeuction of [sverif_prep](userguide#the-sverif_prep-utility).  Its name can be determined by using the `--verbose` option to the utility.

## Statistics Files
Unlike the temporary files described above, the statistics files associated with the SVP are saved between calls to the utilities.  These files are generated by [sverif_prep](userguide#the-sverif_prep-utility), and read by [sverif_eval](userguide#the-sverif_eval-utility), with their naming determined by [sverif_fname.Abs](userguide#the-sverif_fnameabs-utility). By default, all of these files are saved in the directory defined by the `$SVERIF_PREP` [environment variable](#environment-variable); however, this path can be overridden by the `--statpath` option of the SVP utilities.  The "class" definitions in this list are related to the [sverif_fname.Abs](userguide#the-sverif_fnameabs-utility) utility, and all parenthetically-separated names are replaced by their values in the options to the SVP [interface layer](#interface-layer).

1. `sverif-aux_(NAME)(LEVEL)_(PROG)h.dat` ('''`aux`''' class): This file contains confidence interval and inflation information that is generated by the [statistics evaluation](#statistical-valuation-and-plotting) layer of the [sverif_prep](userguide#the-sverif_prep-utility) utility.  It is read and used by the lower layers of [sverif_eval](userguide#the-sverif_eval-utility).  The file is stored as unformatted text.
2. `sverif-precalc_(NAME)(LEVEL)_(PROG)h.dat` ('''`pre`''' class): This file contains summaries of statistical information about the un-perturbed control set of grids (e.g. means, variances) that are required by [sverif_eval](userguide#the-sverif_eval-utility) to compute the test statistics for any subsequent grid.  Values in this file are saved with full precision to avoid rounding errors in sensitive test statistic calculations.  The file is in FST format.
3. `sverif-tstat_(NAME)(LEVEL)_(PROG)h.dat` ('''`tstat`''' class): This file contains columns of the test statistics computed during the bootstrapping step of [sverif_prep](userguide#the-sverif_prep-utility).  It is read used by the [plottinh layer](#statistical-valuation-and-plotting) of [sverif_eval](userguide#the-sverif_eval-utility) to create the test statistics histograms that appear in the backgrounds of the plots.  The file is stored as unformatted text.

The statistics files do not belong to the SVP ''per-se'':  they are results of the precompuatations done on a specific set of gridded inputs.  This means that the package that was used to generate the grids is responsible for managing and distributing these files.  For example, when a benchmark version of GEM is released, it may contain a set of precomputed statistics files and a model configuration that allows users to run integrations in an identical configuration.  The users can then compare the results of their integration (presumably following some code modifications) with the "benchmark" dataset distributed with the model.  They are thereby able to determine whether their modifications push the model solution outside the zone that is considered "similar".

# The sverif_fname.Abs Utility
This utility is designed to manage the names of the (statistics files)[#statistics-files] emloyed by the SVP.  To get a usage message, type:
`bash
 sverif_fname.Abs
 `
Three classes of file can be specified, "aux", "pre" and "tstat" that map directly to the files described in the previous section (see class identifications in parentheses following each file name in the list above).  In addition to a valid class specification, information unique to the dataset must be provided to allow for the construction of meaningful statistical file names that minimize the chance of collisions.  All applications dealing with SVP (statistics files)[#statistics-files] should use this utility rather than relying on file naming conventions.

# Environment Variables
The SVP uses a very limited set of environmetn variables for operation:
* `$SVERIF_STATPATH`:  Used by SVP utilities as the default location of the (statistics files)[#statistics-files] employed by the package.  This value can be overriden by the eplicit definition of the `--statpath` option to the utilities.  The reason for using an environment variable in this case is that packages that provide benchmark precomputed SVP files can define this variable to allow users to access the information without needing to worry about where the files actually come from.  For example, the GEM package could define this variable in its profile to allow any user that ssmuse's GEM, to run the [[Sverif/userguide#The sverif_eval Utility|`sverif_eval`]] directly from the correct set of pre-packaged SVP (statistics files)[#statistics-files].
* `$TMPDIR`: Used by the `tempfile` package of python to determine the base directory for named (temporary files)[#temporary-files]
