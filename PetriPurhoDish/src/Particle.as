package  
{
	import flash.display.Shape;
	import flash.geom.Point;
	
	/**
	* ...
	* @author Anna Zajaczkowski
	*/
	public class Particle extends Shape
	{
		public var position:Point;
		public var velocity:Point;
		public var radius:Number;
		
		public function Particle(_x:Number, _y:Number, velX:Number, velY:Number, r:Number)
		{
			position = new Point(_x, _y);
			x = _x;
			y = _y;
			velocity = new Point(velX, velY);
			radius = r;
			
			graphics.beginFill(0x404040, 1.0);
			graphics.drawCircle(0, 0, radius); // + 8);
			graphics.endFill();
		}
		
		public function get posX():Number
		{
			return position.x;
		}
		
		public function get posY():Number
		{
			return position.y;
		}
		
		public function set posX(value:Number):void
		{
			position.x = value;
		}
		
		public function set posY(value:Number):void
		{
			position.y = value;
		}
		
		public function get velX():Number
		{
			return velocity.x;
		}
		
		public function get velY():Number
		{
			return velocity.y;
		}
		
		public function set velX(value:Number):void
		{
			velocity.x = value;
		}
		
		public function set velY(value:Number):void
		{
			velocity.y = value;
		}
	}
	
}