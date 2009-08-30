package  
{
	import flash.display.Shape;
	import flash.display.Sprite;
	
	/**
	 * ...
	 * @author Anna Zajaczkowski
	 */
	public class DiffLine extends Sprite
	{
		public var lineLength:int = 0;
		public var inactive:Boolean = false;
		private var shapes:Array = new Array();
		public var chars:Array = null; // new Array();
		
		public function DiffLine() 
		{
			
		}
		
		public function addShape(shp:Shape):void
		{
			shapes.push(shp);
			this.addChild(shp);
		}
		
		public function fade():void
		{
			for each (var shp:Shape in shapes)
			{
				shp.alpha = Math.max(0.4, shp.alpha - 0.1);
			}
		}
	}
	
}