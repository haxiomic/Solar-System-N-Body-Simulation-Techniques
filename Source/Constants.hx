package;

class Constants{
	//Physical Law Constants in SI units
	static inline public var G:Float       	 = 6.673840E-11;	//m^3 kg^-1 s^-2
	//conversions from wolfram eg: 'newtons gravitational constant in AU^3 per earth mass per days^2'
	static inline public var G_m_kg_s:Float  = G;	//1.488×10^-34 au^3/(kg day^2)  	(astronomical units cubed per kilogram day squared)
	static inline public var G_AU_kg_s:Float = 1.993E-44;	//1.488×10^-34 au^3/(kg day^2)  	(astronomical units cubed per kilogram day squared)
	static inline public var G_AU_kg_D:Float = 1.488E-34;	//1.488×10^-34 au^3/(kg day^2)  	(astronomical units cubed per kilogram day squared)
	static inline public var G_AU_ME_D:Float = 8.890E-10;	//8.89×10^-10 au^3/(M_(+) day^2)  	(astronomical units cubed per Earth mass day squared)

	//Length Constants SI
	static inline public var AU:Float = 1.495978707E11;//m
	static inline public var AU_m:Float = AU;//m

	//time
	static inline public var secondsInDay:Float = 60*60*24;

}