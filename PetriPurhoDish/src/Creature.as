package  
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.geom.Point;
	import flash.events.MouseEvent;
	
	/**
	* ...
	* @author Anna Zajaczkowski
	*/
	public class Creature extends Shape
	{
		public var center:Particle;
		private var dragging:Boolean = false;
		public var target:Point;
		
		public function Creature(s:Stage)
		{
			s.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			s.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			s.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		}
		
		public function get creatureRadius():Number
		{
			return 0;
		}
		
		public function update():void
		{
			var mouseDist:Point = new Point(stage.mouseX - (stage.stageWidth / 2), stage.mouseY - (stage.stageHeight / 2));
			if (dragging && mouseDist.length < stage.stageHeight / 2)
			{
				posX = stage.mouseX;
				posY = stage.mouseY;
			}
		}
		
		public function setPos(X:Number, Y:Number):void
		{
			posX = X;
			posY = Y;
			center.oldX = X;
			center.oldY = Y;
		}
		
		private function mouseDown(e:MouseEvent):void
		{
			if (e.stageX > posX - 8 && e.stageX < posX + 8 && e.stageY > posY - 8 && e.stageY < posY + 8)
			{
				// start drag
				//trace("drag");
				dragging = true;
			}
			//trace(e.localX);
		}
		
		private function mouseMove(e:MouseEvent):void
		{
			if (e.buttonDown && dragging)
			{
				/*pos.x = e.stageX;
				pos.y = e.stageY;*/
				target.x = e.stageX;
				target.y = e.stageY;
			}
		}
		
		private function mouseUp(e:MouseEvent):void
		{
			dragging = false;
		}
		
		public function get velX():Number
		{
			return center.velX;
		}
		
		public function get velY():Number
		{
			return center.velY;
		}
		
		public function set velX(value:Number):void
		{
			center.velX = value;
		}
		
		public function set velY(value:Number):void
		{
			center.velY = value;
		}
		
		public function get posX():Number
		{
			return center.posX;
		}
		
		public function get posY():Number
		{
			return center.posY;
		}
		
		public function set posX(value:Number):void
		{
			center.posX = value;
		}
		
		public function set posY(value:Number):void
		{
			center.posY = value;
		}
	}
	
}