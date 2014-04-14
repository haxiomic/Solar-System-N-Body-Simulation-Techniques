package;

import geom.Vec3;
import simulator.*;
import renderer.*;
import Experiment.SimulationResults;
import Experiment.ExperimentInformation;

import sysUtils.compileTime.Build;
import sysUtils.compileTime.Git;
import sysUtils.Console;
import sysUtils.FileTools;

class Main {
	var renderer:BasicRenderer;

	var units:Dynamic = {
		time: "days",
		length: "AU",
		mass: "kg"
	};

	/* --- File Config --- */
	var dataOutDirectory = Build.dir()+"/Output Data/";
	/* -------------- */

	public function new () {
		renderer = new BasicRenderer();

		//Basic Test
		{
			var dt = 1;
			var eulerTest = new Experiment(EulersMethod, [Constants.G_AU_kg_D, dt]);

			var sun = eulerTest.addBody({
				name: "Sun",
				position: {x:0, y:0, z:0},
				velocity: {x:0, y:0, z:0},
				mass: 1.988544E30,
			});renderer.addBody(sun, 5, 0xFFFF00);

			var planet = eulerTest.addBody({
				name: "Test Planet",
				position: {x:1, y:0, z:0},
				velocity: {x:0, y:0, z:0.01},
				mass: 5.97219E24,
			});renderer.addBody(planet, 2.5, 0x2288CC);


			//set experiment conditions
			eulerTest.timescale = 10;
			var analysisCount = 100;
			eulerTest.analysisInterval = Math.ceil((eulerTest.timescale/dt)/analysisCount);

			//enable logging
			eulerTest.runtimeCallback = function(e){
				renderer.render();
			}
			eulerTest.runtimeCallbackInterval = 1;

			//perform experiment
			var r:SimulationResults = eulerTest.perform();

			var millionIterationTime = 1000*1000*(r.cpuTime/r.totalIterations);

			Console.newLine();
			Console.print("Total Iterations: "+r.totalIterations+" | CPU Time: "+r.cpuTime+" s  |  1M Iteration: "+millionIterationTime+" s");
			Console.newLine();

			saveExperiment(eulerTest, "Basic Test");
			renderer.preRenderCallback = function(){
				eulerTest.simulator.step();	
			}
			renderer.startAutoRender();
		}

		//Euler's Method Solar System Test
		if(false){
			var dt:Float = 1;
			var eulerTest = new Experiment(EulersMethod, [Constants.G_AU_kg_D, dt]);

			//add bodies
			var sun:Body = eulerTest.addBody(SolarBodyData.sun); renderer.addBody(sun);
			var earth:Body = eulerTest.addBody(SolarBodyData.earth); renderer.addBody(earth);
			var jupiter:Body = eulerTest.addBody(SolarBodyData.jupiter); renderer.addBody(jupiter);
			var saturn:Body = eulerTest.addBody(SolarBodyData.saturn); renderer.addBody(saturn);
			var uranus:Body = eulerTest.addBody(SolarBodyData.uranus); renderer.addBody(uranus);
			var neptune:Body = eulerTest.addBody(SolarBodyData.neptune); renderer.addBody(neptune);

			//set experiment conditions
			eulerTest.timescale = 10000*365; //days
			var analysisCount = 100;
			eulerTest.analysisInterval = Math.ceil((eulerTest.timescale/dt)/analysisCount);

			//enable logging
			eulerTest.runtimeCallback = runtimeLog;
			eulerTest.runtimeCallbackInterval = 1;

			//perform experiment
			var r:SimulationResults = eulerTest.perform();

			//experiment completed
			var millionIterationTime = 1000*1000*(r.cpuTime/r.totalIterations);

			Console.newLine();
			Console.print("Total Iterations: "+r.totalIterations+" | CPU Time: "+r.cpuTime+" s  |  1M Iteration: "+millionIterationTime+" s");
			Console.newLine();

			//save results
			saveExperiment(eulerTest, eulerTest.name);
		}

		//Finish program
		/*Console.newLine();
		Console.printStatement("Press any key to continue");
		Sys.getChar(false);
		Console.newLine();

		exit(0);*/
	}

	var lastLogTime:Float = 0;
	function runtimeLog(e:Experiment){
		if((Sys.time()-lastLogTime) > 1){
			var progress = 100*(e.time-e.timeStart)/e.timescale;
			Console.print(progress+"% "+Sys.time()+"\r", false);
			lastLogTime = Sys.time();
		}
	}

	function saveExperiment(e:Experiment, filePrefix:String = ""){
		var info = e.information;
		var results = e.results;
		var r:Dynamic = Reflect.copy(results);
		r.millionIterationTime = 1000*1000*(r.cpuTime/r.totalIterations)+" s";//add extra field
		//Construct object to save
		var fileSaveData = {
			metadata:{
				date: Build.date(),
				git: Git.lastCommit(),
				gitHash: Git.lastCommitHash(),
				units: units,
			},
			info: info,
			results: results,
		}

		filePrefix = (new haxe.io.Path(filePrefix)).file;//parse filePrefix to make it safe
		if(filePrefix!="")filePrefix+=" - ";

		var parsedAlgorithmName = (new haxe.io.Path(info.algorithmName)).file;
		var filename = filePrefix+info.bodies.length+" bodies, timescale="+Math.round(info.timescale/365)+" years"+".json";
		var fileDir = haxe.io.Path.join([dataOutDirectory, parsedAlgorithmName]);//dataOutDir/parsedAlgorithmName
		var path = haxe.io.Path.join([fileDir, filename]);
		try{
			//Create filename
			saveAsJSON(fileSaveData, path, false);
		}catch(msg:String){
			Console.printError(msg);
			Console.newLine();
			if(Console.askYesNoQuestion("Shall I dump the data to the console?")){
				Console.printTitle("Dumping data to console");
				Console.newLine();
				Console.print(haxe.Json.stringify(fileSaveData));
				Console.newLine();
			}
		}
	}

	/* -------------------------*/
	/* --- System Functions --- */

	static public function saveAsJSON(data:Dynamic, path:String, autoCreateDirectory:Bool = true):Bool{
		var hxPath = new haxe.io.Path(path);

		var filename = hxPath.file;
		//Assess file out directory
		var outDir = haxe.io.Path.normalize(hxPath.dir);

		//Check if out directory exists
		if(!sys.FileSystem.exists(outDir)){
			if(autoCreateDirectory){
				sys.FileSystem.createDirectory(outDir);
			}else{
				//create out directory
				if(Console.askYesNoQuestion("Directory "+outDir+" doesn't exist, create it?", null, false)){
					Console.newLine();
					Console.newLine();
					sys.FileSystem.createDirectory(outDir);
					Console.printSuccess("Directory created");
				}else{
					throw "cannot save data";
					return false;
				}
			}
		}

		//Check the file doesn't already exist, if it does, find a free suffix -xx
		var filePath = FileTools.findFreeFile(hxPath.toString());
		filePath = haxe.io.Path.normalize(filePath);//normalize path for readability

		sys.io.File.saveContent(filePath, haxe.Json.stringify(data));

		Console.printSuccess("Data saved to "+Console.BRIGHT_WHITE+filePath+Console.RESET);

		return true;
	}

	inline function exit(?code:Int){
		if(code==null)code=0;//successful 
		#if cpp
			Sys.exit(code);
		#end
	}

	inline function cpuTime():Float{
		return Sys.cpuTime();
		//return haxe.Timer.stamp();
	}

	static function main(){
		new Main();
	}
}