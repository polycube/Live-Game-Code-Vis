package  
{
	import flash.display.Shape;
	import flash.display.Stage;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author Anna Zajaczkowski
	 */
	public class Diatom extends Creature
	{
		//public var particle:Particle;
		
		public function Diatom(X:Number, Y:Number, s:Stage) 
		{
			super(s);
			
			x = X;
			y = Y;
			
			target = new Point(X, Y);
			
			center = new Particle(X, Y, (Math.random() - 0.5) * 0.5, (Math.random() - 0.5) * 0.5, 8, 1.0, 8.0);
			
			graphics.lineStyle(2, 0x404040, 1.0);
			//graphics.beginFill(0x404040, 1.0);
			
			var numSides:uint = Math.random() * 4 + 4;
			
			graphics.moveTo(8 * Math.cos(0 * Math.PI / numSides * 2), 8 * Math.sin(0 * Math.PI / numSides * 2));
			
			for (var i:uint = 0; i < numSides; i++)
			{
				graphics.lineTo(8 * Math.cos(i * Math.PI / numSides * 2), 8 * Math.sin(i * Math.PI / numSides * 2));
				//Math.random() * 16 + 4);
				//s.addChild(particles[i]);
			}
			graphics.lineTo(8 * Math.cos(0 * Math.PI / numSides * 2), 8 * Math.sin(0 * Math.PI / numSides * 2));
			//graphics.endFill();
		}
		
		public override function update():void
		{
			super.update();
			
			center.integrate();
			x = center.posX;
			y = center.posY;
		}
	}
	
}