package  
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.display.LineScaleMode;
	import flash.text.TextFieldAutoSize;
	
	/**
	 * ...
	 * @author Anna Zajaczkowski
	 */
	public class Drop extends Sprite
	{
		public static var textSize:uint = 8;
		//public static
		private var box:Shape = new Shape();
		
		public function Drop(clr:uint, char:String) 
		{
			box.graphics.beginFill(clr, 1.0);
			//graphics.drawRect( -0.5, -0.5, 1.0, 1.0);
			//graphics.lineStyle(1, clr, 1.0, false, LineScaleMode.NONE);
			box.graphics.drawRect( -0.5, -0.5, 1.0, 1.0);
			//graphics.drawRect( -1.0, -1.0, 2.0, 2.0);
			box.graphics.endFill();
			addChild(box);
			
			var textFormat:TextFormat = new TextFormat();
			textFormat.align = TextFormatAlign.CENTER;
			textFormat.font = "Lucida Console";
			textFormat.size = 8;
			
			var txtChar:TextField = new TextField();
			txtChar.autoSize = TextFieldAutoSize.NONE;
			txtChar.textColor = /*0x282828;*/ clr;
			txtChar.text = char;
			txtChar.setTextFormat(textFormat);
			//txtChar.border = true;
			//txtChar.borderColor = 0xFFFF80;
			txtChar.height = 12;
			txtChar.width = 12;
			//txtChar.width = txtChar.textWidth;
			//txtChar.height = txtChar.textHeight;
			txtChar.scaleX = 0.1;
			txtChar.scaleY = 0.1;
			txtChar.x = -txtChar.width / 2;
			txtChar.y = -txtChar.height / 2;
			txtChar.mouseEnabled = false;
			
			addChild(txtChar);
			
			addEventListener(Event.ENTER_FRAME, update);
			
			//this.alpha = 0.5;
		}
		
		private var vel:Number = 0;
		private var scaleVel:Number = 2.4;
		public static var hVelFactor:Number = 2.0;
		private var hVel:Number = (Math.random() - 0.5) * hVelFactor;
		
		public function update(e:Event):void
		{
			/*this.alpha -= 0.05;
			this.scaleX += this.scaleX * Math.pow(this.alpha, 2.0) * 0.5;
			this.scaleY = this.scaleX;
			this.y += Math.pow(alpha, 2) * 4;
			
			if (this.alpha <= 0) // explosion has faded
			{
				removeEventListener(Event.ENTER_FRAME, update);
				this.parent.removeChild(DisplayObject(this));
			}*/
			
			//if (scaleX < 16)
			
			if (scaleVel > 0)
			{
				box.alpha -= 0.1;
				//scaleX += 0.5;
				scaleX += scaleVel;
				scaleY = scaleX;
				scaleVel -= 0.2;
			}
			else
			{
				vel += 0.25;
				y += vel;
				x += hVel;
				if (box.alpha > 0)
				{
					box.alpha -= 0.05;
				}
			}
			
			if (y * parent.scaleY > stage.stageHeight)
			{
				//trace("bloop");
				removeEventListener(Event.ENTER_FRAME, update);
				this.parent.removeChild(DisplayObject(this));
			}
		}
	}
	
}