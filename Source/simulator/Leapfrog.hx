package simulator;

import simulator.NBodySimulator;

class Leapfrog extends NBodySimulator{
	public var dt:Float;

	public function new(G:Float, dt:Float){
		super(G);
		this.algorithmName = "Leapfrog";
		this.algorithmDetails = "Fixed timestep, 'Kick Drift Kick' & 'Drift Kick Drift' variation.";
		this.dt = dt;
	}

	@:noStack 
	override public function step(){
		stepDKD();
	}

	@:noStack
	inline function stepKDK(){
		var d          : Float;
		var dSq        : Float;
		var fc         : Float;
		for (i in 0...bodyCount){
			//Pairwise kick
			for (j in i+1...bodyCount) {
				position.difference(i, j, r);
				dSq  = r.lengthSquared();
				d    = Math.sqrt(dSq);
				fc   = G / dSq;
				//Normalize r
				r *= 1/d;
				velocity.addProductVec3(i, r, fc*mass[j]*dt*.5);
				velocity.addProductVec3(j, r, -fc*mass[i]*dt*.5);
			}

			//Each-Body Drift
			position.addFn(i, inline function(k) return
				velocity.get(i,k)*dt
			);
		}

		for (i in 0...bodyCount){
			//Pairwise kick
			for (j in i+1...bodyCount) {
				position.difference(i, j, r);
				dSq  = r.lengthSquared();
				d    = Math.sqrt(dSq);
				fc   = G / dSq;
				//Normalize r
				r *= 1/d;
				velocity.addProductVec3(i, r, fc*mass[j]*dt*.5);
				velocity.addProductVec3(j, r, -fc*mass[i]*dt*.5);
			}
		}

		time+=dt;

	}

	@:noStack
	inline function stepDKD(){
		var d          : Float;
		var dSq        : Float;
		var fc         : Float;
		for (i in 0...bodyCount){
			//Each-Body Drift
			position.addFn(i, inline function(k) return
				velocity.get(i,k)*dt*.5
			);
		}
		for (i in 0...bodyCount){
			//Pairwise kick
			for (j in i+1...bodyCount) {
				position.difference(i, j, r);
				dSq  = r.lengthSquared();
				d    = Math.sqrt(dSq);
				fc   = G / dSq;
				//Normalize r
				r *= 1/d;
				velocity.addProductVec3(i, r, fc*mass[j]*dt);
				velocity.addProductVec3(j, r, -fc*mass[i]*dt);
			}

			//Each-Body Drift
			position.addFn(i, inline function(k) return
				velocity.get(i,k)*dt*.5
			);
		}

		time+=dt;
	}

	override function get_params():Dynamic{
		return {dt:dt};
	}	
}

