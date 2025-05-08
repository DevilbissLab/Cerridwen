from jpype import *
import numpy
import sys
# Our python data file readers are a bit of a hack, python users will do better on this:
sys.path.append("/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/infodynamics/demos/python")
import readFloatsFile

if (not isJVMStarted()):
    # Add JIDT jar library to the path
    jarLocation = "/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/infodynamics/infodynamics.jar"
    # Start the JVM (add the "-Xmx" option with say 1024M if you get crashes due to not enough memory space)
    startJVM(getDefaultJVMPath(), "-ea", "-Djava.class.path=" + jarLocation, convertStrings=True)

# 0. Load/prepare the data:
dataRaw = readFloatsFile.readFloatsFile("/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/infodynamics/demos/AutoAnalyser/../data/SFI-heartRate_breathVol_bloodOx-extract.txt")
# As numpy array:
data = numpy.array(dataRaw)
source = JArray(JDouble, 1)(data[:,0].tolist())
destination = JArray(JDouble, 1)(data[:,0].tolist())

# 1. Construct the calculator:
calcClass = JPackage("infodynamics.measures.continuous.kraskov").TransferEntropyCalculatorKraskov
calc = calcClass()
# 2. Set any properties to non-default values:
calc.setProperty("DELAY", "2")
# 3. Initialise the calculator for (re-)use:
calc.initialise()
# 4. Supply the sample data:
calc.setObservations(source, destination)
# 5. Compute the estimate:
result = calc.computeAverageLocalOfObservations()

print("TE_Kraskov (KSG)(col_0 -> col_0) = %.4f nats" %\
    (result))
