package simulator;

import geom.FlatVec3Array;
import haxe.ds.Vector;

class LeapfrogAdaptive extends NBodySimulator{

	var acceleration:FlatVec3Array;
	var stepSize:Vector<Int>;

	var orderedIndicies:Array<Int>;

	var dtBase:Float;//length of time for a step size of 1

	var maxSS:Int;

	var mostMassiveIndex:Int = 0;
	var mostMassiveMass:Float;

	var accuracyParameter:Float;

	public function new(G:Float, minimumTimestep:Float, accuracyParameter:Float = 0.03, maxStepSize = (1<<11)){
		super(G);
		this.algorithmName = "Leapfrog Adaptive";
		this.algorithmDetails = "Block timesteps, schedule approach. Time-symmetrized DSKD scheme. Timestep set by Kepler orbit about most massive body";

		this.dtBase = minimumTimestep;
		this.accuracyParameter = accuracyParameter;
		this.maxSS = maxStepSize;
	}

	override public function prepare(){
		super.prepare();

		acceleration   	 = new FlatVec3Array(this.bodies.length);
		stepSize         = new Vector<Int>(this.bodies.length);
		orderedIndicies  = new Array<Int>();
	
		//Initialize		
		for (i in 0...this.bodies.length){
			acceleration.zero(i);
			orderedIndicies[i] = i;
			stepSize[i] = 1;
			//find most massive body
			if(mass[i]>mass[mostMassiveIndex])mostMassiveIndex = i;
		}

		mostMassiveMass = mass[mostMassiveIndex];
	}

	var s:Int = 0;//current step
	var lastSmallest:Int = 1;
	@:noStack
	override function step(){
		var smallestSS = maxSS;
		var dt;
		var reorder:Bool = false;

		//Open
		for (i in 0...bodyCount){
			var ssOld = stepSize[i];
			var dtOld = dtFromSS(ssOld);
			if(s % ssOld != 0) continue;//continue if it's not time to step body

			//drift forward
			position.addFn(i, inline function(k) return
				velocity.get(i,k)*dtOld*.5
			);

			//Select
			var ssNew;
			if(i == mostMassiveIndex){
				ssNew = lastSmallest;
				stepSize[i] = ssNew;
			}else{
				ssNew = pickSS(i);
				if(s % ssNew == 0){//both bodies are 'closed' - step size can only change at points of synchronization
					stepSize[i] = ssNew;

					//correct position
					dt = dtFromSS(ssNew);
					position.addFn(i, inline function(k) return
						velocity.get(i,k)*(dt-dtOld)*.5
					);
				}
			}

			if(ssNew != ssOld)reorder = true;

			if(stepSize[i] < smallestSS)
				smallestSS = stepSize[i];
		}

		// trace(stepSize);

		//Order
		if(reorder)orderedIndicies.sort(ssAscending);

		//Pairwise kick, from smallest to largest step size
		var d          : Float;
		var dSq        : Float;
		var fc         : Float;
		//reset acceleration
		for (k in 0...bodyCount) {
			var i = orderedIndicies[k];
			if(s % stepSize[i] != 0) continue;//continue if it's not time to step body

			dt = dtFromSS(stepSize[i]);

			for (l in k+1...bodyCount) {
				var j = orderedIndicies[l];

				position.difference(i, j, r);
				dSq  = r.lengthSquared();
				d    = Math.sqrt(dSq);
				fc   = G / dSq;
				r *= 1/d;//normalize r

				velocity.addProductVec3(i, r,  fc*mass[j]*dt);
				velocity.addProductVec3(j, r, -fc*mass[i]*dt);
			}
		}

		//Close
		for (i in 0...bodyCount){
			if(Std.int(s+smallestSS) % stepSize[i] != 0) continue;//continue if it's not time to step body

			//Each-Body Drift
			dt = dtFromSS(stepSize[i]);
			position.addFn(i, inline function(k) return
				velocity.get(i,k)*dt*.5
			);
		}

		time += dtFromSS(smallestSS);
		s += smallestSS;
		s = s%maxSS;//wrap around

		lastSmallest = smallestSS;
	}

	@:noStack
	inline function pickSS(i:Int){
		var dSq     : Float;
		var dCu     : Float;
		var idealDt : Float;
		var idealSS : Float;
		position.difference(i, mostMassiveIndex, r);
		dSq = r.lengthSquared();
		dCu = dSq*Math.sqrt(dSq);
		idealDt = accuracyParameter*Math.sqrt(dCu/(G*mostMassiveMass));

		idealSS = idealDt/dtBase;

		return idealSS < maxSS ? base2Foor(idealSS) : maxSS;
	}

	inline function dtFromSS(ss:Int):Float return ss*dtBase;

	inline function base2Foor(x:Float):Int{
		var br:Int = 0;
		var y:Int = Std.int(x);
		while((y >>= 1) > 0) ++br;
		return 1 << br;
	}

	inline function ssAscending(i:Int, j:Int):Int 
		return stepSize[i] - stepSize[j];//a-b => smallest to largest

	override function get_params():Dynamic{
		return {
			minimumTimestep:dtBase,
			accuracyParameter:accuracyParameter,
			maxStepSize:maxSS,
		};
	}	
}