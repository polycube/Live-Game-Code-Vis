package  
{
	
	/**
	 * ...
	 * @author Anna Zajaczkowski
	 */
	public class CodeLine 
	{
		public var chars:Array = new Array(1);
		public var lineType:uint = 0;
		
		public function CodeLine() 
		{
			chars[0] = new Array();
		}
		
		public function get lineLength():uint
		{
			return chars.length;
		}
	}
	
}