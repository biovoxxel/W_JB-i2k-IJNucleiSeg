// Author: Sébastien Tosi (IRB Barcelona)
// modified by Volker Bäcker to make it run
// in batch mode, reading parameters from the command line
//
// The macro will segment nuclei and separate clustered nuclei
// using a binary watershed. As a result an index-mask image is
// written for each input image.
// Use FIJI to run the macro with a command similar to
// java -Xmx6000m -cp jars/ij.jar ij.ImageJ -headless --console -macro IJSegmentClusteredNuclei.ijm "input=/media/baecker/donnees/mri/projects/2017/liege/in, output=/media/baecker/donnees/mri/projects/2017/liege/out, radius=5, threshold=-0.5"


// Version: 1.3
// Date: 28/04/2017


setBatchMode(true);

// Path to input image and output image (label mask)
inputDir = "/dockershare/666/in/";
outputDir = "/dockershare/666/out/";

// Functional parameters
LapRad = 5;
LapThr = -0.5;

arg = getArgument();
parts = split(arg, ",");

for(i=0; i<parts.length; i++) {
	nameAndValue = split(parts[i], "=");
	if (indexOf(nameAndValue[0], "input")>-1) inputDir=nameAndValue[1];
	if (indexOf(nameAndValue[0], "output")>-1) outputDir=nameAndValue[1];
	if (indexOf(nameAndValue[0], "radius")>-1) LapRad=nameAndValue[1];
	if (indexOf(nameAndValue[0], "threshold")>-1) LapThr=nameAndValue[1];
}

images = getFileList(inputDir);

for(i=0; i<images.length; i++) {
	image = images[i];
	if (endsWith(image, ".tif")) {
		// Open image
		open(inputDir + "/" + image);
		wait(100);
		// Pre-processing
	// performing a flat-field correction
		run("Duplicate...", "title=[dup_"+image+"]");
		duplicate = getTitle();
		run("Gaussian Blur...", "sigma=30");
		getStatistics(area, mean);
		run("Calculator Plus", "i1="+image+" i2="+duplicate+" operation=[Divide: i2 = (i1/i2) x k1 + k2] k1="+mean+" k2=0 create");
	
		run("Median...", "radius=1");
		lightingCorrected = getTitle();
	
		// Segment
		setOption("BlackBackground", true);
		run("Auto Threshold", "method=Li white");
		run("Dilate");
		run("Watershed");

		// Analyze
		run("Analyze Particles...", "size=20-Infinity circularity=0.50-1.00 show=[Count Masks] clear include in_situ");

		// Export results
		save(outputDir + "/" + image);
		
		// Cleanup
		run("Close All");
	}
}
run("Quit");
