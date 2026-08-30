%[text] # Getting Started
%[text] The **Individual Cone Fundamentals Toolbox** computes the LMS cone spectral sensitivities of a particular observer, and the quantities derived from them. Those include the RGB colour matching functions, the CIE XYZ colour matching functions, photopic luminance $V^{\\ast}(\\lambda)$ and the chromaticity coordinates.
%[text] The observer is described by biophysical parameters: the opsin genotype, the age, the retinal field size, and the optical densities of the lens, the macular pigment and the photopigment.
%[text] The defaults reproduce the CIE 170-1:2006 standard observers. They do so through the Stockman & Rider (2023) formulae rather than the published tables, which the formulae follow to about 0.02 in units where the peak sensitivity is 1.0. [Example 01](matlab:open('Example01_Basics.m')) gives the exact figures. Every parameter can be set individually, to model a particular observer or to vary one quantity at a time.
%[text] This guide is a short orientation and a map of the worked examples. Run the cell below, then open whichever example covers what you need.
%[text] These files are plain-text Live Scripts. In R2025a and later the text renders as formatted prose. In earlier releases the `%[text]` markers appear as comments, and every file still runs correctly as an ordinary script.
%%
%[text] ## A first observer
%[text] `IndividualCMF` called with no arguments returns the CIE 2006 10 deg standard observer. Evaluate one cone with `obs.L(wl)`, `obs.M(wl)` or `obs.S(wl)`, or all three with `obs.LMS(wl)`. Wavelengths may be given as a row or a column, and these files use columns throughout.
%[text] `evaluate` returns the same numbers as a table, with the wavelengths and the cone names attached.
obs = IndividualCMF();
obs.evaluate((450:50:650)', Data='LMS')
%[text] The toolbox exists to build observers other than the standard one. Any biophysical parameter can be set in the constructor, and the result reports itself as individualized.
IndividualCMF(Age=70, LensModel="VanDeKraats2007")
%[text] `plotLMS` draws the same three cone fundamentals. It plots whatever the observer's output settings produce, so the curves reach 1.0 here only because `NormalizeOutput` is true by default. See [Example 05](matlab:open('Example05_OutputFormats.m')).
obs.plotLMS(Title="CIE 2006 10 deg cone fundamentals");
xlim([380 780]); ylim([0 1.05])
%%
%[text] ## The examples
%[text] The toolbox includes 20 worked examples, ordered roughly from the basics to more specialized topics. Click one to open it.
%[text:table]
%[text] | # | Example | What it covers |
%[text] | --- | --- | --- |
%[text] | 01 | [The Basics](matlab:open('Example01_Basics.m')) | Create an observer, evaluate the cones, plot them, and see what normalization does |
%[text] | 02 | [Standard Observers](matlab:open('Example02_StandardObservers.m')) | The CIE 2006 2 deg and 10 deg observers, and the XYZ colour matching functions |
%[text] | 03 | [How an Observer Is Assembled](matlab:open('Example03_HowAnObserverIsAssembled.m')) | The three components, the two controls each one has, and what `CIE170` selects |
%[text] | 04 | [Computational Pipeline](matlab:open('Example04_ComputationalPipeline.m')) | The four stages from absorbance to corneal sensitivity |
%[text] | 05 | [Output Formats](matlab:open('Example05_OutputFormats.m')) | `energy`, `quantal`, `absorptance` and `absorbance`, and `LogOutput` |
%[text] | 06 | [Normalization Methods](matlab:open('Example06_NormalizationMethods.m')) | The two ways of locating the peak, and matching another implementation |
%[text] | 07 | [Field Size Effects](matlab:open('Example07_FieldSizeEffects.m')) | Macular pigment and photopigment density as functions of field size |
%[text] | 08 | [Aging Effects](matlab:open('Example08_AgingEffects.m')) | How the lens changes with age, and the three `LensModel` choices |
%[text] | 09 | [Genetic Variants](matlab:open('Example09_GeneticVariants.m')) | The Ser180Ala polymorphism, hybrid cones, and the `Genotype` argument |
%[text] | 10 | [Photopigment Models](matlab:open('Example10_PhotopigmentModels.m')) | Stockman & Rider 2023 and Govardovskii 2000 compared |
%[text] | 11 | [RGB Color Matching](matlab:open('Example11_RGBColorMatching.m')) | RGB colour matching functions, negative values, and custom primaries |
%[text] | 12 | [Chromaticity Diagrams](matlab:open('Example12_ChromaticityDiagrams.m')) | lm and CIE xy chromaticity, and the spectrum locus |
%[text] | 13 | [Photopic Luminance](matlab:open('Example13_Luminance.m')) | $V^{\\ast}(\\lambda)$ and MacLeod-Boynton coordinates |
%[text] | 14 | [Observer Comparison](matlab:open('Example14_ObserverComparison.m')) | `compareTo`, difference measures, and several observers at once |
%[text] | 15 | [Dichromacy](matlab:open('Example15_Dichromacy.m')) | Modelling a missing cone with an optical density of zero |
%[text] | 16 | [Advanced Customization](matlab:open('Example16_AdvancedCustomization.m')) | Every parameter, the Custom-mode rules, and saving and restoring an observer |
%[text] | 17 | [Data Export](matlab:open('Example17_DataExport.m')) | `evaluate`, and writing CSV and MAT files |
%[text] | 18 | [Publication Figures](matlab:open('Example18_PublicationFigures.m')) | Multi-panel figures and how to export them |
%[text] | 19 | [Working with Measured Spectra](matlab:open('Example19_MeasuredSpectra.m')) | Reading a measured spectrum and integrating it against an observer |
%[text] | 20 | [Observer Metamerism](matlab:open('Example20_ObserverMetamerism.m')) | How a match made for one observer fails for another |
%[text:table]
%%
%[text] ## Further reading
%[text] - The examples folder holds a README with the full learning path and a time estimate for each example \
%[text] - The public API is documented in the class help. Run `help IndividualCMF` \
%[text] - `ARCHITECTURE.md` describes the internal design, including the class layering, the four-stage pipeline and how to add a template. It is in the repository at [github.com/sfu-cs-vision-lab/individual-cmfs-matlab](https://github.com/sfu-cs-vision-lab/individual-cmfs-matlab) rather than in the installed toolbox

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
