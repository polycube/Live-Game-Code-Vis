package name.fraser.neil.plaintext
{
	public class ArrayIterator
	{
		private var items:Array;
	
	private var cursor:int = 0;
	
	private var lastRet:int = -1;;
	
	/**
	 * Constructor.
	 * 
	 * @param array The array of elements to construct and Iterator for
	 */
	public function ArrayIterator( array:Array )
	{
		items = array;
		// If the array is null, create a new empty array
		if ( items == null )
		{
			items = new Array();
		}
	}
	
	/** 
	 * @return <code>true</code> if the iteration has more elements, false otherwise.
	 */
	public function hasNext():Boolean
	{
		return cursor != items.length;
	}
	
	/** 
	 * @return The next element in the iteration. 
	 */
	public function next():*
	{
		var next = items[cursor];
		lastRet = cursor++;
		return next;
	}
	
	public function remove():void {
		if (lastRet == -1) {
			trace("error in iterator remove called without next or previous!");
			return;
		}
		items.splice(lastRet, 1);
		if (lastRet < cursor) {
			cursor--;
		} 
		lastRet = -1;
	}
	
	public function hasPrevious():Boolean {
		return cursor != 0;
	}
	
	public function set(obj):void {
		if (lastRet == -1) {
			trace("error in iterator set called without next or previous!");
			return;
		}
		items[lastRet] = obj;
	}
	
	public function add(obj):void {
		items.splice(cursor++, 0, obj);// this should be in place
		lastRet = -1;
	}

	
	public function previous():*
	{
		var i:int = cursor-1;
		var previous = items[i];
		cursor = i;
		lastRet = i;
		return previous;
	}
	
	/**
	 * Resets the iterator's state to start from the very first element.
	 */
	public function reset():void
	{
		cursor = 0;
		lastRet = -1;
	}
	

	}
}