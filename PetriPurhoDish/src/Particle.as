package  
{
	import flash.display.Shape;
	import flash.geom.Point;
	
	/**
	* ...
	* @author Anna Zajaczkowski
	*/
	public class Particle
	{
		private var position:Point;
		private var oldPosition:Point;
		public var velocity:Point;
		private var damping:Number;
		public var radius:Number;
		public var maxSpeed:Number;
		
		public function Particle(_x:Number, _y:Number, velX:Number, velY:Number, r:Number, drag:Number, maxS:Number)
		{
			position = new Point(_x, _y);
			oldPosition = new Point(position.x, position.y);
			velocity = new Point(velX, velY);
			radius = r;
			damping = drag;
			maxSpeed = maxS;
		}
		
		public function integrate():void
		{
			var temp:Point = new Point(position.x, position.y);
			
			var vel:Point = new Point(
				(position.x - oldPosition.x + velocity.x) * damping,
				(position.y - oldPosition.y + velocity.y) * damping);
			
			if (vel.length > maxSpeed)
			{
				vel.normalize(maxSpeed);
			}
			
			//position.x += (position.x - oldPosition.x + velocity.x) * damping;
			//position.y += (position.y - oldPosition.y + velocity.y) * damping;
			position.x += vel.x;
			position.y += vel.y;
			
			oldPosition.x = temp.x;
			oldPosition.y = temp.y;
			
			velocity.x = 0;
			velocity.y = 0;
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
		
		public function get oldX():Number
		{
			return oldPosition.x;
		}
		
		public function get oldY():Number
		{
			return oldPosition.y;
		}
		
		public function set oldX(value:Number):void
		{
			oldPosition.x = value;
		}
		
		public function set oldY(value:Number):void
		{
			oldPosition.y = value;
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