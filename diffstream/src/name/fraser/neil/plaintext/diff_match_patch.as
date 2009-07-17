package name.fraser.neil.plaintext
{
	import flash.utils.getTimer;
	
	public class diff_match_patch
	{
		
	  // Defaults.
	  // Set these on your diff_match_patch instance to override the defaults.
	
	  // Number of seconds to map a diff before giving up.  (0 for infinity)
	  public var Diff_Timeout:Number  = 1.0;
	  // Cost of an empty edit operation in terms of edit characters.
	  public var Diff_EditCost:int  = 4;
	  // The size beyond which the double-ended diff activates.
	  // Double-ending is twice as fast, but less accurate.
	  public var Diff_DualThreshold:int = 32;
	  // Tweak the relative importance (0.0 = accuracy, 1.0 = proximity)
	  public var Match_Balance:Number = 0.5;
	  // At what point is no match declared (0.0 = perfection, 1.0 = very loose)
	  public var Match_Threshold:Number = 0.5;
	  // The min and max cutoffs used when computing text lengths.
	  public var Match_MinLength:int = 100;
	  public var Match_MaxLength:int = 1000;
	  // Chunk size for context length.
	  public var Patch_Margin:int = 4;
	
	  // The number of bits in an int.
	  private var Match_MaxBits:int = 32;


		
		  /**
   * Find the differences between two texts.
   * Run a faster slightly less optimal diff
   * This method allows the 'checklines' of diff_main() to be optional.
   * Most of the time checklines is wanted, so default to true.
   * @param text1 Old string to be diffed.
   * @param text2 New string to be diffed.
   * @return Linked List of Diff objects.
   */
  public function diff_main(text1:String, text2:String):Array { // was LinkedList<Diff> {
    return diff_main2(text1, text2, true);
  }
  
   /**
   * Find the differences between two texts.  Simplifies the problem by
   * stripping any common prefix or suffix off the texts before diffing.
   * @param text1 Old string to be diffed.
   * @param text2 New string to be diffed.
   * @param checklines Speedup flag.  If false, then don't run a
   *     line-level diff first to identify the changed areas.
   *     If true, then run a faster slightly less optimal diff
   * @return Linked List of Diff objects.
   */
  public function diff_main2(text1:String , text2:String, checklines:Boolean):Array { // was LinkedList<Diff> {
    // Check for equality (speedup)
    var diffs:Array; // LinkedList<Diff>
    if (text1 == text2) {
      diffs = new Array();//LinkedList<Diff>();
      diffs.push(new Diff(Operation.EQUAL, text1));
      return diffs;
    }

    // Trim off common prefix (speedup)
    var commonlength:int = diff_commonPrefix(text1, text2);
    var commonprefix:String = text1.substring(0, commonlength);
    text1 = text1.substring(commonlength);
    text2 = text2.substring(commonlength);

    // Trim off common suffix (speedup)
    commonlength = diff_commonSuffix(text1, text2);
    var commonsuffix:String = text1.substring(text1.length - commonlength);
    text1 = text1.substring(0, text1.length - commonlength);
    text2 = text2.substring(0, text2.length - commonlength);

    // Compute the diff on the middle block
    diffs = diff_compute(text1, text2, checklines);

    // Restore the prefix and suffix
    if (commonprefix.length != 0) {
      diffs.unshift(new Diff(Operation.EQUAL, commonprefix));
    }
    if (commonsuffix.length != 0) {
      diffs.push(new Diff(Operation.EQUAL, commonsuffix));
    }

    diff_cleanupMerge(diffs);
    return diffs;
  }
  
  /**
   * Find the differences between two texts.  Assumes that the texts do not
   * have any common prefix or suffix.
   * @param text1 Old string to be diffed.
   * @param text2 New string to be diffed.
   * @param checklines Speedup flag.  If false, then don't run a
   *     line-level diff first to identify the changed areas.
   *     If true, then run a faster slightly less optimal diff
   * @return Linked List of Diff objects.
   */
  public function diff_compute(text1:String, text2:String, checklines:Boolean):Array { // was LinkedList<Diff> {
    var diffs:Array = new Array();// LinkedList<Diff>();

    if (text1.length == 0) {
      // Just add some text (speedup)
      diffs.push(new Diff(Operation.INSERT, text2));
      return diffs;
    }

    if (text2.length == 0) {
      // Just delete some text (speedup)
      diffs.push(new Diff(Operation.DELETE, text1));
      return diffs;
    }

    var longtext:String = text1.length > text2.length ? text1 : text2;
    var shorttext:String = text1.length > text2.length ? text2 : text1;
    var i:int = longtext.indexOf(shorttext);
    if (i != -1) {
      // Shorter text is inside the longer text (speedup)
      var op:Operation = (text1.length > text2.length) ?
                     Operation.DELETE : Operation.INSERT;
      diffs.push(new Diff(op, longtext.substring(0, i)));
      diffs.push(new Diff(Operation.EQUAL, shorttext));
      diffs.push(new Diff(op, longtext.substring(i + shorttext.length)));
      return diffs;
    }
    longtext = shorttext = null;  // Garbage collect

    // Check to see if the problem can be split in two.
    var hm:Array /*String[]*/ = diff_halfMatch(text1, text2);
    if (hm != null) {
      // A half-match was found, sort out the return data.
      var text1_a:String = hm[0];
      var text1_b:String = hm[1];
      var text2_a:String = hm[2];
      var text2_b:String = hm[3];
      var mid_common:String = hm[4];
      // Send both pairs off for separate processing.
      var diffs_a:Array /*LinkedList<Diff>*/ = diff_main2(text1_a, text2_a, checklines);
      var diffs_b:Array /*LinkedList<Diff>*/ = diff_main2(text1_b, text2_b, checklines);
      // Merge the results.
      diffs = diffs_a;
      diffs.push(new Diff(Operation.EQUAL, mid_common));
      diffs = diffs.concat(diffs_b);
      return diffs;
    }

    // Perform a real diff.
    if (checklines && (text1.length < 100 || text2.length < 100)) {
      checklines = false;  // Too trivial for the overhead.
    }
    var linearray:Array = null; //ArrayList<String>
    if (checklines) {
      // Scan the text on a line-by-line basis first.
      var b:Array /*Object[]*/= diff_linesToChars(text1, text2);
      text1 = b[0]; // cast to String
      text2 = b[1]; // cast to String
      // The following Java warning is harmless.
      // Suggestions for how to clear it would be appreciated.
      linearray = b[2]; // cast to (ArrayList<String>)
     }

    diffs = diff_map(text1, text2);
    if (diffs == null) {
      // No acceptable result.
      diffs = new Array(); // LinkedList<Diff>();
      diffs.push(new Diff(Operation.DELETE, text1));
      diffs.push(new Diff(Operation.INSERT, text2));
    }

    if (checklines) {
      // Convert the diff back to original text.
      diff_charsToLines(diffs, linearray);
      // Eliminate freak matches (e.g. blank lines)
      diff_cleanupSemantic(diffs);

      // Rediff any replacement blocks, this time character-by-character.
      // Add a dummy entry at the end.
      diffs.push(new Diff(Operation.EQUAL, ""));
      var count_delete:int = 0;
      var count_insert:int = 0;
      var text_delete:String = "";
      var text_insert:String = "";
      
      var pointer:ArrayIterator /*ListIterator<Diff>*/ = new ArrayIterator(diffs); 
      var thisDiff:Diff = pointer.next();
      while (thisDiff != null) {
        switch (thisDiff.operation) {
        case Operation.INSERT:
          count_insert++;
          text_insert += thisDiff.text;
          break;
        case Operation.DELETE:
          count_delete++;
          text_delete += thisDiff.text;
          break;
        case Operation.EQUAL:
          // Upon reaching an equality, check for prior redundancies.
          if (count_delete >= 1 && count_insert >= 1) {
            // Delete the offending records and add the merged ones.
            pointer.previous();
            for (var j:int = 0; j < count_delete + count_insert; j++) {
              pointer.previous();
              pointer.remove();
            }
            for each (var newDiff:Diff in diff_main2(text_delete, text_insert, false)) {
              pointer.add(newDiff); // WHATCHFOR - this needs to be implemented
            }
          }
          count_insert = 0;
          count_delete = 0;
          text_delete = "";
          text_insert = "";
          break;
        }
        thisDiff = pointer.hasNext() ? pointer.next() : null;
      }
      diffs.pop();  // Remove the dummy entry at the end.
    }
    return diffs;
  }


  /**
   * Split two texts into a list of strings.  Reduce the texts to a string of
   * hashes where each Unicode character represents one line.
   * @param text1 First string.
   * @param text2 Second string.
   * @return Three element Object array, containing the encoded text1, the
   *     encoded text2 and the List of unique strings.  The zeroth element
   *     of the List of unique strings is intentionally blank.
   */
  public function diff_linesToChars(text1:String, text2:String):Array { // was Object[] {
    var lineArray:Array = new Array(); // List<String>
    var lineHash:Array = new Array(); //HashMap<String, Integer>();
    // e.g. linearray[4] == "Hello\n"
    // e.g. linehash.get("Hello\n") == 4

    // "\x00" is a valid character, but various debuggers don't like it.
    // So we'll insert a junk entry to avoid generating a null character.
    lineArray.push("");

    var chars1:String = diff_linesToCharsMunge(text1, lineArray, lineHash);
    var chars2:String = diff_linesToCharsMunge(text2, lineArray, lineHash);
    return [chars1, chars2, lineArray];// new Object[]{chars1, chars2, lineArray};
  }


  /**
   * Split a text into a list of strings.  Reduce the texts to a string of
   * hashes where each Unicode character represents one line.
   * @param text String to encode.
   * @param lineArray List of unique strings.
   * @param lineHash Map of strings to indices.
   * @return Encoded string.
   */
  private function diff_linesToCharsMunge(text:String, lineArray:Array /*was List<String>*/,
                                          lineHash:Array /* was Map<String, Integer>*/):String {
    var lineStart:int = 0;
    var lineEnd:int = -1;
    var line:String;
    var chars:String = ""; // StringBuilder
    // Walk the text, pulling out a substring for each line.
    // text.split('\n') would would temporarily double our memory footprint.
    // Modifying text would create many large strings to garbage collect.
    while (lineEnd < text.length - 1) {
      lineEnd = text.indexOf('\n', lineStart);
      if (lineEnd == -1) {
        lineEnd = text.length - 1;
      }
      line = text.substring(lineStart, lineEnd + 1);
      lineStart = lineEnd + 1;

      if (lineHash[line] != null) {
        chars = chars.concat(String.fromCharCode((lineHash[line] as int)));
      } else {
        lineArray.push(line);
        lineHash[line] = lineArray.length - 1;
        chars = chars.concat(""+String.fromCharCode(lineArray.length - 1));
      }
    }
    return chars.toString();
  }


  /**
   * Rehydrate the text in a diff from a string of line hashes to real lines of
   * text.
   * @param diffs LinkedList of Diff objects.
   * @param lineArray List of unique strings.
   */
  public function diff_charsToLines(diffs:Array /*LinkedList<Diff>*/,
                                    lineArray:Array /*List<String>*/):void {
    var text:String; // StringBuilder
    for each (var diff:Diff in diffs) {
      text = "";
      for (var y:int = 0; y < diff.text.length; y++) {
      	//trace(diff.text.charAt(y) + " " + diff.text.charCodeAt(y));
        text = text.concat(lineArray[diff.text.charCodeAt(y)]);
      }
      diff.text = text.toString();
    }
  }


  /**
   * Explore the intersection points between the two texts.
   * @param text1 Old string to be diffed.
   * @param text2 New string to be diffed.
   * @return LinkedList of Diff objects or null if no diff available.
   */
  public function diff_map(text1:String, text2:String):Array { // was LinkedList<Diff> {
    var ms_end:Number = getTimer() + (Diff_Timeout * 1000) as Number;
    var max_d:int = text1.length + text2.length - 1;
    var doubleEnd:Boolean = Diff_DualThreshold * 2 < max_d;
    var v_map1:Array = new Array(); // List<Set<Long>>
    var v_map2:Array = new Array(); // List<Set<Long>>
    var v1:Array = new Array(); //HashMap<Integer, Integer>();
    var v2:Array = new Array();//HashMap<Integer, Integer>();
    v1[1] = 0;
    v2[1] = 0;
    var x:int, y:int;
    var footstep:Number = 0;  // Used to track overlapping paths.
    var footsteps:Array = new Array();//HashMap<Long, Integer>();
    var done:Boolean = false;
    // If the total number of characters is odd, then the front path will
    // collide with the reverse path.
    var front:Boolean = ((text1.length + text2.length) % 2 == 1);
    for (var d:int = 0; d < max_d; d++) {
      // Bail out if timeout reached.
      if (Diff_Timeout > 0 && getTimer() > ms_end) {
        return null;
      }

      // Walk the front path one step.
      v_map1.push(new Array());  // Adds at index 'd'.   new HashSet<Long>()
      for (var k:int = -d; k <= d; k += 2) {
        if (k == -d || k != d && v1[k - 1] < v1[k + 1]) {
          x = v1[k + 1];
        } else {
          x = v1[k - 1] + 1;
        }
        y = x - k;
        if (doubleEnd) {
          footstep = diff_footprint(x, y);
          if (front && (footsteps[footstep] != null)) {
            done = true;
          }
          if (!front) {
            footsteps[footstep] = d;
          }
        }
        while (!done && x < text1.length && y < text2.length
               && text1.charAt(x) == text2.charAt(y)) {
          x++;
          y++;
          if (doubleEnd) {
            footstep = diff_footprint(x, y);
            if (front && (footsteps[footstep] != null)) {
              done = true;
            }
            if (!front) {
              footsteps[footstep] = d;
            }
          }
        }
        v1[k] = x;
        v_map1[d].push(diff_footprint(x, y));
        if (x == text1.length && y == text2.length) {
          // Reached the end in single-path mode.
          return diff_path1(v_map1, text1, text2);
        } else if (done) {
          // Front path ran over reverse path.
          v_map2 = v_map2.slice(0, footsteps[footstep] + 1);
          var a:Array = diff_path1(v_map1, text1.substring(0, x),
                                          text2.substring(0, y)); // was List
          a = a.concat(diff_path2(v_map2, text1.substring(x), text2.substring(y)));
          return a;
        }
      }

      if (doubleEnd) {
        // Walk the reverse path one step.
        v_map2.push(new Array());  // Adds at index 'd'. new HashSet<Long>()
        for (var k:int = -d; k <= d; k += 2) {
          if (k == -d || k != d && v2[k - 1] < v2[k + 1]) {
            x = v2[k + 1];
          } else {
            x = v2[k - 1] + 1;
          }
          y = x - k;
          footstep = diff_footprint(text1.length - x, text2.length - y);
          if (!front && (footsteps[footstep] != null)) {
            done = true;
          }
          if (front) {
            footsteps[footstep] = d;
          }
          while (!done && x < text1.length && y < text2.length
                 && text1.charAt(text1.length - x - 1)
                 == text2.charAt(text2.length - y - 1)) {
            x++;
            y++;
            footstep = diff_footprint(text1.length - x, text2.length - y);
            if (!front && (footsteps[footstep] != null)) {
              done = true;
            }
            if (front) {
              footsteps[footstep] = d;
            }
          }
          v2[k] = x;
          v_map2[d].push(diff_footprint(x, y));
          if (done) {
            // Reverse path ran over front path.
            v_map1 = v_map1.slice(0, footsteps[footstep] + 1);
            var a:Array // LinkedList<Diff>
                = diff_path1(v_map1, text1.substring(0, text1.length - x),
                             text2.substring(0, text2.length - y));
            a = a.concat(diff_path2(v_map2, text1.substring(text1.length - x),
                                text2.substring(text2.length - y)));
            return a;
          }
        }
      }
    }
    // Number of diffs equals number of characters, no commonality at all.
    return null;
  }


  /**
   * Work from the middle back to the start to determine the path.
   * @param v_map List of path sets.
   * @param text1 Old string fragment to be diffed.
   * @param text2 New string fragment to be diffed.
   * @return LinkedList of Diff objects.
   */
  public function diff_path1(v_map:Array /* was List<Set<Long>>*/,
                                        text1:String, text2:String):Array {// was LinkedList<Diff> {
    var path:Array = new Array();//LinkedList<Diff>();
    var x:int = text1.length;
    var y:int = text2.length;
    var last_op:Operation = null;
    for (var d:int = v_map.length - 2; d >= 0; d--) {
      while (true) {
        if (v_map[d].indexOf(diff_footprint(x - 1, y)) != -1) {
          x--;
          if (last_op == Operation.DELETE) {
            path[0].text = text1.charAt(x) + path[0].text;
          } else {
            path.unshift(new Diff(Operation.DELETE,
                                   text1.substring(x, x + 1)));
          }
          last_op = Operation.DELETE;
          break;
        } else if (v_map[d].indexOf(diff_footprint(x, y - 1)) != -1) {
          y--;
          if (last_op == Operation.INSERT) {
            path[0].text = text2.charAt(y) + path[0].text;
          } else {
            path.unshift(new Diff(Operation.INSERT,
                                   text2.substring(y, y + 1)));
          }
          last_op = Operation.INSERT;
          break;
        } else {
          x--;
          y--;
//          assert (text1.charAt(x) == text2.charAt(y))
//                 : "No diagonal.  Can't happen. (diff_path1)";
          if (last_op == Operation.EQUAL) {
            path[0].text = text1.charAt(x) + path[0].text;
          } else {
            path.unshift(new Diff(Operation.EQUAL, text1.substring(x, x + 1)));
          }
          last_op = Operation.EQUAL;
        }
      }
    }
    return path;
  }


  /**
   * Work from the middle back to the end to determine the path.
   * @param v_map List of path sets.
   * @param text1 Old string fragment to be diffed.
   * @param text2 New string fragment to be diffed.
   * @return LinkedList of Diff objects.
   */
  public function diff_path2(v_map:Array /*List<Set<Long>>*/,
								text1:String, text2:String):Array { // was LinkedList<Diff> {
    var path:Array = new Array();//LinkedList<Diff>();
    var x:int = text1.length;
    var y:int = text2.length;
    var last_op:Operation = null;
    for (var d:int = v_map.length - 2; d >= 0; d--) {
      while (true) {
        if (v_map[d].indexOf(diff_footprint(x - 1, y)) != -1) {
          x--;
          if (last_op == Operation.DELETE) {
            path[path.length-1].text += text1.charAt(text1.length - x - 1);
          } else {
            path.push(new Diff(Operation.DELETE,
                text1.substring(text1.length - x - 1, text1.length - x)));
          }
          last_op = Operation.DELETE;
          break;
        } else if (v_map[d].indexOf(diff_footprint(x, y - 1)) != -1) {
          y--;
          if (last_op == Operation.INSERT) {
            path[path.length-1].text += text2.charAt(text2.length - y - 1);
          } else {
            path.push(new Diff(Operation.INSERT,
                text2.substring(text2.length - y - 1, text2.length - y)));
          }
          last_op = Operation.INSERT;
          break;
        } else {
          x--;
          y--;
//          assert (text1.charAt(text1.length() - x - 1)
//                  == text2.charAt(text2.length() - y - 1))
//                 : "No diagonal.  Can't happen. (diff_path2)";
          if (last_op == Operation.EQUAL) {
            path[path.length-1].text += text1.charAt(text1.length - x - 1);
          } else {
            path.push(new Diff(Operation.EQUAL,
                text1.substring(text1.length - x - 1, text1.length - x)));
          }
          last_op = Operation.EQUAL;
        }
      }
    }
    return path;
  }


  /**
   * Compute a good hash of two integers.
   * @param x First int.
   * @param y Second int.
   * @return A long made up of both ints.
   */
  public function diff_footprint(x:int, y:int):Number {
    // The maximum size for a long is 9,223,372,036,854,775,807
    // The maximum size for an int is 2,147,483,647
    // Two ints fit nicely in one long.
    // The return value is usually destined as a key in a hash, so return an
    // object rather than a primitive, thus skipping an automatic boxing.
    var result:Number = x;
    var shiftVal:Number = Math.pow(2,32);
    result = result * shiftVal;
    result += y;
    return result;
  }


  /**
   * Determine the common prefix of two strings
   * @param text1 First string.
   * @param text2 Second string.
   * @return The number of characters common to the start of each string.
   */
  public function diff_commonPrefix(text1:String, text2:String):int {
    // Performance analysis: http://neil.fraser.name/news/2007/10/09/
    var n:int = Math.min(text1.length, text2.length);
    for (var i:int = 0; i < n; i++) {
      if (text1.charAt(i) != text2.charAt(i)) {
        return i;
      }
    }
    return n;
  }


  /**
   * Determine the common suffix of two strings
   * @param text1 First string.
   * @param text2 Second string.
   * @return The number of characters common to the end of each string.
   */
  public function diff_commonSuffix(text1:String, text2:String):int {
    // Performance analysis: http://neil.fraser.name/news/2007/10/09/
    var n:int = Math.min(text1.length, text2.length);
    for (var i:int = 0; i < n; i++) {
      if (text1.charAt(text1.length - i - 1)
          != text2.charAt(text2.length - i - 1)) {
        return i;
      }
    }
    return n;
  }


  /**
   * Do the two texts share a substring which is at least half the length of
   * the longer text?
   * @param text1 First string.
   * @param text2 Second string.
   * @return Five element String array, containing the prefix of text1, the
   *     suffix of text1, the prefix of text2, the suffix of text2 and the
   *     common middle.  Or null if there was no match.
   */
  public function diff_halfMatch(text1:String, text2:String):Array { // String[] {
    var longtext:String = text1.length > text2.length ? text1 : text2;
    var shorttext:String = text1.length > text2.length ? text2 : text1;
    if (longtext.length < 10 || shorttext.length < 1) {
      return null;  // Pointless.
    }

    // First check if the second quarter is the seed for a half-match.
    var hm1:Array /*String[]*/ = diff_halfMatchI(longtext, shorttext,
                                   (longtext.length + 3) / 4);
    // Check again based on the third quarter.
    var hm2:Array /*String[]*/ = diff_halfMatchI(longtext, shorttext,
                                   (longtext.length + 1) / 2);
    var hm:Array /*String[]*/;
    if (hm1 == null && hm2 == null) {
      return null;
    } else if (hm2 == null) {
      hm = hm1;
    } else if (hm1 == null) {
      hm = hm2;
    } else {
      // Both matched.  Select the longest.
      hm = hm1[4].length > hm2[4].length ? hm1 : hm2;
    }

    // A half-match was found, sort out the return data.
    if (text1.length > text2.length) {
      return hm;
      //return new String[]{hm[0], hm[1], hm[2], hm[3], hm[4]};
    } else {
      return [hm[2], hm[3], hm[0], hm[1], hm[4]]; // new String[]{
    }
  }


  /**
   * Does a substring of shorttext exist within longtext such that the
   * substring is at least half the length of longtext?
   * @param longtext Longer string.
   * @param shorttext Shorter string.
   * @param i Start index of quarter length substring within longtext.
   * @return Five element String array, containing the prefix of longtext, the
   *     suffix of longtext, the prefix of shorttext, the suffix of shorttext
   *     and the common middle.  Or null if there was no match.
   */
  function diff_halfMatchI(longtext:String, shorttext:String, i:int):Array { // was String[] {
    // Start with a 1/4 length substring at position i as a seed.
    var seed:String = longtext.substring(i, i + longtext.length / 4);
    var j:int = -1;
    var best_common:String  = "";
    var best_longtext_a:String  = "", best_longtext_b = "";
    var best_shorttext_a:String  = "", best_shorttext_b = "";
    while ((j = shorttext.indexOf(seed, j + 1)) != -1) {
      var prefixLength:int = diff_commonPrefix(longtext.substring(i),
                                           shorttext.substring(j));
      var suffixLength:int = diff_commonSuffix(longtext.substring(0, i),
                                           shorttext.substring(0, j));
      if (best_common.length < suffixLength + prefixLength) {
        best_common = shorttext.substring(j - suffixLength, j)
            + shorttext.substring(j, j + prefixLength);
        best_longtext_a = longtext.substring(0, i - suffixLength);
        best_longtext_b = longtext.substring(i + prefixLength);
        best_shorttext_a = shorttext.substring(0, j - suffixLength);
        best_shorttext_b = shorttext.substring(j + prefixLength);
      }
    }
    if (best_common.length >= longtext.length / 2) {
      return [best_longtext_a, best_longtext_b,
                          best_shorttext_a, best_shorttext_b, best_common]; // String[]
    } else {
      return null;
    }
  }


  /**
   * Reduce the number of edits by eliminating semantically trivial equalities.
   * @param diffs LinkedList of Diff objects.
   */
  public function diff_cleanupSemantic(diffs:Array/*LinkedList<Diff>*/):void {
    if (diffs.length == 0) {
      return;
    }
    var changes:Boolean = false;
    var equalities:Array = new Array();//Stack<Diff>();  // Stack of qualities.
    var lastequality:String = null; // Always equal to equalities.lastElement().text
    var pointer:ArrayIterator = new ArrayIterator(diffs);  // .listIterator();
    // Number of characters that changed prior to the equality.
    var length_changes1:int = 0;
    // Number of characters that changed after the equality.
    var length_changes2:int = 0;
    var thisDiff:Diff = pointer.next();
    while (thisDiff != null) {
      if (thisDiff.operation == Operation.EQUAL) {
        // equality found
        equalities.push(thisDiff);
        length_changes1 = length_changes2;
        length_changes2 = 0;
        lastequality = thisDiff.text;
      } else {
        // an insertion or deletion
        length_changes2 += thisDiff.text.length;
        if (lastequality != null && (lastequality.length <= length_changes1)
            && (lastequality.length <= length_changes2)) {
          //System.out.println("Splitting: '" + lastequality + "'");
          // Walk back to offending equality.
          while (thisDiff != equalities[equalities.length-1]) {
            thisDiff = pointer.previous();
          }
          pointer.next();

          // Replace equality with a delete.
          pointer.set(new Diff(Operation.DELETE, lastequality));
          // Insert a corresponding an insert.
          pointer.add(new Diff(Operation.INSERT, lastequality));

          equalities.pop();  // Throw away the equality we just deleted.
          if (!equalities.length == 0) {
            // Throw away the previous equality (it needs to be reevaluated).
            equalities.pop();
          }
          if (equalities.length == 0) {
            // There are no previous equalities, walk back to the start.
            while (pointer.hasPrevious()) {
              pointer.previous();
            }
          } else {
            // There is a safe equality we can fall back to.
            thisDiff = equalities[equalities.length-1];
            while (thisDiff != pointer.previous()) {
              // Intentionally empty loop.
            }
          }

          length_changes1 = 0;  // Reset the counters.
          length_changes2 = 0;
          lastequality = null;
          changes = true;
        }
      }
      thisDiff = pointer.hasNext() ? pointer.next() : null;
    }

    if (changes) {
      diff_cleanupMerge(diffs);
    }
    diff_cleanupSemanticLossless(diffs);
  }


  /**
   * Look for single edits surrounded on both sides by equalities
   * which can be shifted sideways to align the edit to a word boundary.
   * e.g: The c<ins>at c</ins>ame. -> The <ins>cat </ins>came.
   * @param diffs LinkedList of Diff objects.
   */
  public function diff_cleanupSemanticLossless(diffs:Array /*LinkedList<Diff>*/):void {
    var equality1:String, edit:String, equality2:String;
    var commonString:String;
    var commonOffset:int;
    var score:int, bestScore:int;
    var bestEquality1:String, bestEdit:String, bestEquality2:String;
    // Create a new iterator at the start.
    var pointer:ArrayIterator = new ArrayIterator(diffs); // ListIterator<Diff> .listIterator
    var prevDiff:Diff = pointer.hasNext() ? pointer.next() : null;
    var thisDiff:Diff = pointer.hasNext() ? pointer.next() : null;
    var nextDiff:Diff = pointer.hasNext() ? pointer.next() : null;
    // Intentionally ignore the first and last element (don't need checking).
    while (nextDiff != null) {
      if (prevDiff.operation == Operation.EQUAL &&
          nextDiff.operation == Operation.EQUAL) {
        // This is a single edit surrounded by equalities.
        equality1 = prevDiff.text;
        edit = thisDiff.text;
        equality2 = nextDiff.text;

        // First, shift the edit as far left as possible.
        commonOffset = diff_commonSuffix(equality1, edit);
        if (commonOffset != 0) {
          commonString = edit.substring(edit.length - commonOffset);
          equality1 = equality1.substring(0, equality1.length - commonOffset);
          edit = commonString + edit.substring(0, edit.length - commonOffset);
          equality2 = commonString + equality2;
        }

        // Second, step character by character right, looking for the best fit.
        bestEquality1 = equality1;
        bestEdit = edit;
        bestEquality2 = equality2;
        bestScore = diff_cleanupSemanticScore(equality1, edit)
            + diff_cleanupSemanticScore(edit, equality2);
        while (edit.length != 0 && equality2.length != 0
            && edit.charAt(0) == equality2.charAt(0)) {
          equality1 += edit.charAt(0);
          edit = edit.substring(1) + equality2.charAt(0);
          equality2 = equality2.substring(1);
          score = diff_cleanupSemanticScore(equality1, edit)
              + diff_cleanupSemanticScore(edit, equality2);
          // The >= encourages trailing rather than leading whitespace on edits.
          if (score >= bestScore) {
            bestScore = score;
            bestEquality1 = equality1;
            bestEdit = edit;
            bestEquality2 = equality2;
          }
        }

        if (prevDiff.text != bestEquality1) {
          // We have an improvement, save it back to the diff.
          if (bestEquality1.length != 0) {
            prevDiff.text = bestEquality1;
          } else {
            pointer.previous(); // Walk past nextDiff.
            pointer.previous(); // Walk past thisDiff.
            pointer.previous(); // Walk past prevDiff.
            pointer.remove(); // Delete prevDiff.
            pointer.next(); // Walk past thisDiff.
            pointer.next(); // Walk past nextDiff.
          }
          thisDiff.text = bestEdit;
          if (bestEquality2.length != 0) {
            nextDiff.text = bestEquality2;
          } else {
            pointer.remove(); // Delete nextDiff.
            nextDiff = thisDiff;
            thisDiff = prevDiff;
          }
        }
      }
      prevDiff = thisDiff;
      thisDiff = nextDiff;
      nextDiff = pointer.hasNext() ? pointer.next() : null;
    }
  }


  /**
   * Given two strings, compute a score representing whether the internal
   * boundary falls on logical boundaries.
   * Scores range from 5 (best) to 0 (worst).
   * @param one First string.
   * @param two Second string.
   * @return The score.
   */
  function diff_cleanupSemanticScore(one:String, two:String):int {
    if (one.length == 0 || two.length == 0) {
      // Edges are the best.
      return 5;
    }

    // Each port of this function behaves slightly differently due to
    // subtle differences in each language's definition of things like
    // 'whitespace'.  Since this function's purpose is largely cosmetic,
    // the choice has been made to use each language's native features
    // rather than force total conformity.
    var score:int = 0;
    // One point for non-alphanumeric.
    if (!isLetterOrDigit(one.charAt(one.length - 1))
        || !isLetterOrDigit(two.charAt(0))) {
      score++;
      // Two points for whitespace.
      if (isWhitespace(one.charAt(one.length - 1))
          || isWhitespace(two.charAt(0))) {
        score++;
        // Three points for line breaks.
        // WHATCHFOR - find CONTROL characters and add another point.
        if (isControl(one.charAt(one.length - 1))
          || isControl(two.charAt(0))) {
          score++;
          // Four points for blank lines.
          if (one.search(BLANKLINEEND) != -1
              || two.search(BLANKLINESTART) != -1) {
            score++;
          }
        }
      }
    }
    return score;
  }
  
  	public static function isWhitespace(str):Boolean {
    	return !isNaN(Number(" "+str+" 0"));
	}
  
  	public static function isCode(str:String, min:Number, max:Number):Boolean {
         var len:Number = str.length;
         while (len--) {
	          var num:Number = str.substr(len, 1).charCodeAt(0);
	          if (num<min || num>max) {
	              return false;
	              break;
	          }
	 	}
	    return true;
	}
	
	public static function isControl(str:String):Boolean {
		return (isCode(str, 0x00, 0x1F) || isCode(str, 0x7F, 0x9F));
	}
  
  	public static function isLowerCase(str:String):Boolean {
		return (isCode(str, 0x61, 0x7a));
	}
  
   public static function isUpperCase(str:String):Boolean {
      return (isCode(str, 0x41, 0x5a));
   }

   public static function isDigit(str:String):Boolean {
       return (isCode(str, 0x30, 0x39));
   }
  
  public static function isLetter(str:String):Boolean {
       return (isUpperCase(str) || isLowerCase(str));
  }
  
  public static function isLetterOrDigit(str:String):Boolean {
       return (isLetter(str) || isDigit(str));
  }
  
  


  var BLANKLINEEND:RegExp = new RegExp("\\n\\r?\\n\\Z", "g"); // Pattern.DOTALL ??
  var BLANKLINESTART:RegExp = new RegExp("\\A\\r?\\n\\r?\\n", "g"); // Pattern.DOTALL ??
  
  /**
   * Reduce the number of edits by eliminating operationally trivial equalities.
   * @param diffs LinkedList of Diff objects.
   */
  public function diff_cleanupEfficiency(diffs:Array /*LinkedList<Diff>*/):void {
    if (diffs.length == 0) {
      return;
    }
    var changes:Boolean = false;
    var equalities:Array = new Array();//new Stack<Diff>();  // Stack of equalities.
    var lastequality:String = null; // Always equal to equalities.lastElement().text
    var pointer:ArrayIterator = new ArrayIterator(diffs);// ListIterator<Diff> .listIterator();
    // Is there an insertion operation before the last equality.
    var pre_ins:Boolean = false;
    // Is there a deletion operation before the last equality.
    var pre_del:Boolean = false;
    // Is there an insertion operation after the last equality.
    var post_ins:Boolean = false;
    // Is there a deletion operation after the last equality.
    var post_del:Boolean = false;
    var thisDiff:Diff = pointer.next();
    var safeDiff:Diff = thisDiff;  // The last Diff that is known to be unsplitable.
    while (thisDiff != null) {
      if (thisDiff.operation == Operation.EQUAL) {
        // equality found
        if (thisDiff.text.length < Diff_EditCost && (post_ins || post_del)) {
          // Candidate found.
          equalities.push(thisDiff);
          pre_ins = post_ins;
          pre_del = post_del;
          lastequality = thisDiff.text;
        } else {
          // Not a candidate, and can never become one.
          equalities = new Array();
          lastequality = null;
          safeDiff = thisDiff;
        }
        post_ins = post_del = false;
      } else {
        // an insertion or deletion
        if (thisDiff.operation == Operation.DELETE) {
          post_del = true;
        } else {
          post_ins = true;
        }
        /*
         * Five types to be split:
         * <ins>A</ins><del>B</del>XY<ins>C</ins><del>D</del>
         * <ins>A</ins>X<ins>C</ins><del>D</del>
         * <ins>A</ins><del>B</del>X<ins>C</ins>
         * <ins>A</del>X<ins>C</ins><del>D</del>
         * <ins>A</ins><del>B</del>X<del>C</del>
         */
        if (lastequality != null
            && ((pre_ins && pre_del && post_ins && post_del)
                || ((lastequality.length < Diff_EditCost / 2)
                    && ((pre_ins ? 1 : 0) + (pre_del ? 1 : 0)
                        + (post_ins ? 1 : 0) + (post_del ? 1 : 0)) == 3))) {
          //System.out.println("Splitting: '" + lastequality + "'");
          // Walk back to offending equality.
          while (thisDiff != equalities[equalities.length-1]) {
            thisDiff = pointer.previous();
          }
          pointer.next();

          // Replace equality with a delete.
          pointer.set(new Diff(Operation.DELETE, lastequality));
          // Insert a corresponding an insert.
          pointer.add(thisDiff = new Diff(Operation.INSERT, lastequality));

          equalities.pop();  // Throw away the equality we just deleted.
          lastequality = null;
          if (pre_ins && pre_del) {
            // No changes made which could affect previous entry, keep going.
            post_ins = post_del = true;
            equalities = new Array();
            safeDiff = thisDiff;
          } else {
            if (!equalities.length == 0) {
              // Throw away the previous equality (it needs to be reevaluated).
              equalities.pop();
            }
            if (equalities.length == 0) {
              // There are no previous questionable equalities,
              // walk back to the last known safe diff.
              thisDiff = safeDiff;
            } else {
              // There is an equality we can fall back to.
              thisDiff = equalities[equalities.length-1];
            }
            while (thisDiff != pointer.previous()) {
              // Intentionally empty loop.
            }
            post_ins = post_del = false;
          }

          changes = true;
        }
      }
      thisDiff = pointer.hasNext() ? pointer.next() : null;
    }

    if (changes) {
      diff_cleanupMerge(diffs);
    }
  }


  /**
   * Reorder and merge like edit sections.  Merge equalities.
   * Any edit section can move as long as it doesn't cross an equality.
   * @param diffs LinkedList of Diff objects.
   */
  public function diff_cleanupMerge(diffs:Array /*LinkedList<Diff>*/):void {
    diffs.push(new Diff(Operation.EQUAL, ""));  // Add a dummy entry at the end.
    var pointer:ArrayIterator = new ArrayIterator(diffs);// .listIterator(); ListIterator<Diff>
    var count_delete:int = 0;
    var count_insert:int = 0;
    var text_delete:String = "";
    var text_insert:String = "";
    var thisDiff:Diff = pointer.next();
    var prevEqual:Diff = null;
    var commonlength:int;
    while (thisDiff != null) {
      switch (thisDiff.operation) {
      case Operation.INSERT:
        count_insert++;
        text_insert += thisDiff.text;
        prevEqual = null;
        break;
      case Operation.DELETE:
        count_delete++;
        text_delete += thisDiff.text;
        prevEqual = null;
        break;
      case Operation.EQUAL:
        if (count_delete != 0 || count_insert != 0) {
          // Delete the offending records.
          pointer.previous();  // Reverse direction.
          while (count_delete-- > 0) {
            pointer.previous();
            pointer.remove();
          }
          while (count_insert-- > 0) {
            pointer.previous();
            pointer.remove();
          }
          if (count_delete != 0 && count_insert != 0) {
            // Factor out any common prefixies.
            commonlength = diff_commonPrefix(text_insert, text_delete);
            if (commonlength != 0) {
              if (pointer.hasPrevious()) {
                thisDiff = pointer.previous();
//                assert thisDiff.operation == Operation.EQUAL
//                       : "Previous diff should have been an equality.";
                thisDiff.text += text_insert.substring(0, commonlength);
                pointer.next();
              } else {
                pointer.add(new Diff(Operation.EQUAL,
                    text_insert.substring(0, commonlength)));
              }
              text_insert = text_insert.substring(commonlength);
              text_delete = text_delete.substring(commonlength);
            }
            // Factor out any common suffixies.
            commonlength = diff_commonSuffix(text_insert, text_delete);
            if (commonlength != 0) {
              thisDiff = pointer.next();
              thisDiff.text = text_insert.substring(text_insert.length
                  - commonlength) + thisDiff.text;
              text_insert = text_insert.substring(0, text_insert.length
                  - commonlength);
              text_delete = text_delete.substring(0, text_delete.length
                  - commonlength);
              pointer.previous();
            }
          }
          // Insert the merged records.
          if (text_delete.length != 0) {
            pointer.add(new Diff(Operation.DELETE, text_delete));
          }
          if (text_insert.length != 0) {
            pointer.add(new Diff(Operation.INSERT, text_insert));
          }
          // Step forward to the equality.
          thisDiff = pointer.hasNext() ? pointer.next() : null;
        } else if (prevEqual != null) {
          // Merge this equality with the previous one.
          prevEqual.text += thisDiff.text;
          pointer.remove();
          thisDiff = pointer.previous();
          pointer.next();  // Forward direction
        }
        count_insert = 0;
        count_delete = 0;
        text_delete = "";
        text_insert = "";
        prevEqual = thisDiff;
        break;
      }
      thisDiff = pointer.hasNext() ? pointer.next() : null;
    }
    
    // System.out.println(diff);
    if (diffs[diffs.length-1].text.length == 0) {
      diffs.pop();  // Remove the dummy entry at the end.
    }

    /*
     * Second pass: look for single edits surrounded on both sides by equalities
     * which can be shifted sideways to eliminate an equality.
     * e.g: A<ins>BA</ins>C -> <ins>AB</ins>AC
     */
    var changes:Boolean = false;
    // Create a new iterator at the start.
    // (As opposed to walking the current one back.)
    pointer = new ArrayIterator(diffs);
    var prevDiff:Diff = pointer.hasNext() ? pointer.next() : null;
    thisDiff = pointer.hasNext() ? pointer.next() : null;
    var nextDiff:Diff = pointer.hasNext() ? pointer.next() : null;
    // Intentionally ignore the first and last element (don't need checking).
    while (nextDiff != null) {
      if (prevDiff.operation == Operation.EQUAL &&
          nextDiff.operation == Operation.EQUAL) {
        // This is a single edit surrounded by equalities.
        if (thisDiff.text.lastIndexOf(prevDiff.text) == thisDiff.text.length-prevDiff.text.length) {
          // Shift the edit over the previous equality.
          thisDiff.text = prevDiff.text
              + thisDiff.text.substring(0, thisDiff.text.length
                                           - prevDiff.text.length);
          nextDiff.text = prevDiff.text + nextDiff.text;
          pointer.previous(); // Walk past nextDiff.
          pointer.previous(); // Walk past thisDiff.
          pointer.previous(); // Walk past prevDiff.
          pointer.remove(); // Delete prevDiff.
          pointer.next(); // Walk past thisDiff.
          thisDiff = pointer.next(); // Walk past nextDiff.
          nextDiff = pointer.hasNext() ? pointer.next() : null;
          changes = true;
        } else if (thisDiff.text.indexOf(nextDiff.text) == 0) {
          // Shift the edit over the next equality.
          prevDiff.text += nextDiff.text;
          thisDiff.text = thisDiff.text.substring(nextDiff.text.length)
              + nextDiff.text;
          pointer.remove(); // Delete nextDiff.
          nextDiff = pointer.hasNext() ? pointer.next() : null;
          changes = true;
        }
      }
      prevDiff = thisDiff;
      thisDiff = nextDiff;
      nextDiff = pointer.hasNext() ? pointer.next() : null;
    }
    // If shifts were made, the diff needs reordering and another shift sweep.
    if (changes) {
      diff_cleanupMerge(diffs);
    }
  }


  /**
   * loc is a location in text1, compute and return the equivalent location in
   * text2.
   * e.g. "The cat" vs "The big cat", 1->1, 5->8
   * @param diffs LinkedList of Diff objects.
   * @param loc Location within text1.
   * @return Location within text2.
   */
  public function diff_xIndex(diffs:Array/*LinkedList<Diff>*/, loc:int):int {
    var chars1:int = 0;
    var chars2:int = 0;
    var last_chars1:int = 0;
    var last_chars2:int = 0;
    var lastDiff:Diff = null;
    for each (var aDiff:Diff in diffs) {
      if (aDiff.operation != Operation.INSERT) {
        // Equality or deletion.
        chars1 += aDiff.text.length;
      }
      if (aDiff.operation != Operation.DELETE) {
        // Equality or insertion.
        chars2 += aDiff.text.length;
      }
      if (chars1 > loc) {
        // Overshot the location.
        lastDiff = aDiff;
        break;
      }
      last_chars1 = chars1;
      last_chars2 = chars2;
    }
    if (lastDiff != null && lastDiff.operation == Operation.DELETE) {
      // The location was deleted.
      return last_chars2;
    }
    // Add the remaining character length.
    return last_chars2 + (loc - last_chars1);
  }


  /**
   * Convert a Diff list into a pretty HTML report.
   * @param diffs LinkedList of Diff objects.
   * @return HTML representation.
   */
  public function diff_prettyHtml(diffs:Array /*LinkedList<Diff>*/):String {
    var html = "";// new StringBuilder();
    var i:int = 0;
    for each (var aDiff:Diff in diffs) {
      var lessThan:RegExp = new RegExp("<", "g");
      var greaterThan:RegExp = new RegExp(">", "g");
      var amp:RegExp = new RegExp("&", "g");
      var newline:RegExp = new RegExp("\n", "g");
      
      var text:String = aDiff.text.replace(amp, "&amp;").replace(lessThan, "&lt;")
          .replace(greaterThan, "&gt;").replace(newline, "&para;<BR>");
      switch (aDiff.operation) {
      case Operation.INSERT:
        html = html.concat("<INS STYLE=\"background:#E6FFE6;\" TITLE=\"i=").concat(i)
            .concat("\">").concat(text).concat("</INS>");
        break;
      case Operation.DELETE:
        html = html.concat("<DEL STYLE=\"background:#FFE6E6;\" TITLE=\"i=").concat(i)
            .concat("\">").concat(text).concat("</DEL>");
        break;
      case Operation.EQUAL:
        html = html.concat("<SPAN TITLE=\"i=").concat(i).concat("\">").concat(text)
            .concat("</SPAN>");
        break;
      }
      if (aDiff.operation != Operation.DELETE) {
        i += aDiff.text.length;
      }
    }
    return html.toString();
  }

  /**
   * Compute and return the source text (all equalities and deletions).
   * @param diffs LinkedList of Diff objects.
   * @return Source text.
   */
  public function diff_text1(diffs:Array /*LinkedList<Diff>*/):String {
    var text:String = "";//new StringBuilder();
    for each (var aDiff:Diff in diffs) {
      if (aDiff.operation != Operation.INSERT) {
        text = text.concat(aDiff.text);
      }
    }
    return text.toString();
  }

  /**
   * Compute and return the destination text (all equalities and insertions).
   * @param diffs LinkedList of Diff objects.
   * @return Destination text.
   */
  public function diff_text2(diffs:Array /*LinkedList<Diff>*/):String {
    var text:String = "";//new StringBuilder();
    for each (var aDiff:Diff in diffs) {
      if (aDiff.operation != Operation.DELETE) {
        text = text.concat(aDiff.text);
      }
    }
    return text.toString();
  }


  /**
   * Crush the diff into an encoded string which describes the operations
   * required to transform text1 into text2.
   * E.g. =3\t-2\t+ing  -> Keep 3 chars, delete 2 chars, insert 'ing'.
   * Operations are tab-separated.  Inserted text is escaped using %xx notation.
   * @param diffs Array of diff tuples.
   * @return Delta text.
   */
  public function diff_toDelta(diffs:Array /*LinkedList<Diff>*/):String {
    var text:String = "";//new StringBuilder();
    for each (var aDiff:Diff in diffs) {
      switch (aDiff.operation) {
      case Operation.INSERT:
        try {
        	// http://bugs.adobe.com/jira/browse/ASC-3464?page=com.atlassian.jira.plugin.system.issuetabpanels:all-tabpanel
		    // actionscripts escape method replaces spaces with "%20" instead of "+" as is done in the URLEncoder.encode of java.
			var pattern:RegExp = new RegExp("%20", "g");
			
			var escaped:String = encodeURI(aDiff.text);
			//trace(escaped);
			text = text.concat("+").concat(escaped.replace(pattern, ' ')).concat("\t");
        } catch (e) {
          // Not likely on modern system.
          throw new Error("This system does not support UTF-8.", e);
        }
        break;
      case Operation.DELETE:
        text = text.concat("-").concat(aDiff.text.length).concat("\t");
        break;
      case Operation.EQUAL:
        text = text.concat("=").concat(aDiff.text.length).concat("\t");
        break;
      }
    }
    var delta:String = text.toString();
    if (delta.length != 0) {
      // Strip off trailing tab character.
      delta = delta.substring(0, delta.length - 1);
      delta = unescapeForEncodeUriCompatability(delta);
    }
    return delta;
  }


  /**
   * Given the original text1, and an encoded string which describes the
   * operations required to transform text1 into text2, compute the full diff.
   * @param text1 Source string for the diff.
   * @param delta Delta text.
   * @return Array of diff tuples or null if invalid.
   * @throw IllegalArgumentException If invalid input.
   */
  public function diff_fromDelta(text1:String, delta:String):Array {// was LinkedList<Diff>
      //throws IllegalArgumentException {
    var diffs:Array = new Array();//LinkedList<Diff>();
    var pointer:int = 0;  // Cursor in text1
    var tokens:Array = delta.split("\t"); // String[]
    for each (var token:String in tokens) {
      if (token.length == 0) {
        // Blank tokens are ok (from a trailing \t).
        continue;
      }
      // Each token begins with a one character parameter which specifies the
      // operation of this token (delete, insert, equality).
      var param:String = token.substring(1);
      var option = token.charAt(0);
      switch (option) {
      case '+':
        // decode would change all "+" to " "
        var pattern:RegExp = new RegExp("+", "g");
        param = param.replace(pattern, "%2B");
        try {
			param = unescape(param);
        } catch (err) {
          // Not likely on modern system.
//          throw new Error("This system does not support UTF-8 OR Illegal escape in diff_fromDelta.", e);
			trace("This system does not support UTF-8 OR Illegal escape in diff_fromDelta.");
        }
        diffs.push(new Diff(Operation.INSERT, param));
        break;
      case '-':
        // Fall through.
      case '=':
        var n:int;
        try {
          n = int(param); // Integer.parseInt 
        } catch (e) {
//          throw new IllegalArgumentException(
             trace( "Invalid number in diff_fromDelta: " + param + " " +  e);
        }
        if (n < 0) {
//          throw new Error( // IllegalArgumentException(
              trace("Negative number in diff_fromDelta: " + param);
        }
        var text:String;
        try {
          text = text1.substring(pointer, pointer += n);
        } catch (e) { // StringIndexOutOfBoundsException 
//          throw new IllegalArgumentException(
          trace("Delta length (" + pointer
              + ") larger than source text length (" + text1.length
              + ")." + " " +  e);
        }
        if (token.charAt(0) == '=') {
          diffs.push(new Diff(Operation.EQUAL, text));
        } else {
          diffs.push(new Diff(Operation.DELETE, text));
        }
        break;
      default:
        // Anything else is an error.
//        throw new IllegalArgumentException(
            trace("Invalid diff operation in diff_fromDelta: " + token.charAt(0));
      }
    }
    if (pointer != text1.length) {
//      throw new IllegalArgumentException("Delta length (" + pointer
         trace("Delta length () smaller than source text length (" + text1.length + ").");
    }
    return diffs;
  }


  //  MATCH FUNCTIONS


  /**
   * Locate the best instance of 'pattern' in 'text' near 'loc'.
   * Returns -1 if no match found.
   * @param text The text to search.
   * @param pattern The pattern to search for.
   * @param loc The location to search around.
   * @return Best match index or -1.
   */
  public function match_main(text:String, pattern:String, loc:int):int {
    loc = Math.max(0, Math.min(loc, text.length - pattern.length));
    if (text == pattern) {
      // Shortcut (potentially not guaranteed by the algorithm)
      return 0;
    } else if (text.length == 0) {
      // Nothing to match.
      return -1;
    } else if (text.substring(loc, loc + pattern.length) == pattern) {
      // Perfect match at the perfect spot!  (Includes case of null pattern)
      return loc;
    } else {
      // Do a fuzzy compare.
      return match_bitap(text, pattern, loc);
    }
  }


  /**
   * Locate the best instance of 'pattern' in 'text' near 'loc' using the
   * Bitap algorithm.  Returns -1 if no match found.
   * @param text The text to search.
   * @param pattern The pattern to search for.
   * @param loc The location to search around.
   * @return Best match index or -1.
   */
  public function match_bitap(text:String, pattern:String, loc:int):int  {
//    assert (Match_MaxBits == 0 || pattern.length() <= Match_MaxBits)
//        : "Pattern too long for this application.";

    // Initialise the alphabet.
    var s:Array = match_alphabet(pattern); // Map<Character, Integer>

    var score_text_length:int = text.length;
    // Coerce the text length between reasonable maximums and minimums.
    score_text_length = Math.max(score_text_length, Match_MinLength);
    score_text_length = Math.min(score_text_length, Match_MaxLength);

    // Highest score beyond which we give up.
    var score_threshold:Number = Match_Threshold; // double
    // Is there a nearby exact match? (speedup)
    var best_loc:int = text.indexOf(pattern, loc);
    if (best_loc != -1) {
      score_threshold = Math.min(match_bitapScore(0, best_loc, loc,
          score_text_length, pattern), score_threshold);
    }
    // What about in the other direction? (speedup)
    best_loc = text.lastIndexOf(pattern, loc + pattern.length);
    if (best_loc != -1) {
      score_threshold = Math.min(match_bitapScore(0, best_loc, loc,
          score_text_length, pattern), score_threshold);
    }

    // Initialise the bit arrays.
    var matchmask:int = 1 << (pattern.length - 1);
    best_loc = -1;

    var bin_min:int, bin_mid:int;
    var bin_max:int = Math.max(loc + loc, text.length);
    // Empty initialization added to appease Java compiler.
    var last_rd:Array = new Array();// int[0];
    for (var d:int = 0; d < pattern.length; d++) {
      // Scan for the best match; each iteration allows for one more error.
      var rd:Array = new Array();//int[text.length()];

      // Run a binary search to determine how far from 'loc' we can stray at
      // this error level.
      bin_min = loc;
      bin_mid = bin_max;
      while (bin_min < bin_mid) {
        if (match_bitapScore(d, bin_mid, loc, score_text_length, pattern)
            < score_threshold) {
          bin_min = bin_mid;
        } else {
          bin_max = bin_mid;
        }
        bin_mid = (bin_max - bin_min) / 2 + bin_min;
      }
      // Use the result from this iteration as the maximum for the next.
      bin_max = bin_mid;
      var start:int = Math.max(0, loc - (bin_mid - loc) - 1);
      var finish:int = Math.min(text.length - 1, pattern.length + bin_mid);

      if (text.charAt(finish) == pattern.charAt(pattern.length - 1)) {
        rd[finish] = (1 << (d + 1)) - 1;
      } else {
        rd[finish] = (1 << d) - 1;
      }
      for (var j:int = finish - 1; j >= start; j--) {
        if (d == 0) {
          // First pass: exact match.
          rd[j] = ((rd[j + 1] << 1) | 1) & (s[text.charAt(j)] != null
              ? s[text.charAt(j)]
              : 0);
        } else {
          // Subsequent passes: fuzzy match.
          rd[j] = ((rd[j + 1] << 1) | 1) & (s[text.charAt(j)] != null
              ? s[text.charAt(j)] : 0) | ((last_rd[j + 1] << 1) | 1)
              | ((last_rd[j] << 1) | 1) | last_rd[j + 1];
        }
        if ((rd[j] & matchmask) != 0) {
          var score:Number = match_bitapScore(d, j, loc, score_text_length,
                                          pattern);
          // This match will almost certainly be better than any existing
          // match.  But check anyway.
          if (score <= score_threshold) {
            // Told you so.
            score_threshold = score;
            best_loc = j;
            if (j > loc) {
              // When passing loc, don't exceed our current distance from loc.
              start = Math.max(0, loc - (j - loc));
            } else {
              // Already passed loc, downhill from here on in.
              break;
            }
          }
        }
      }
      if (match_bitapScore(d + 1, loc, loc, score_text_length, pattern)
          > score_threshold) {
        // No hope for a (better) match at greater error levels.
        break;
      }
      last_rd = rd;
    }
    return best_loc;
  }


  /**
   * Compute and return the score for a match with e errors and x location.
   * @param e Number of errors in match.
   * @param x Location of match.
   * @param loc Expected location of match.
   * @param score_text_length Coerced version of text's length.
   * @param pattern Pattern being sought.
   * @return Overall score for match.
   */
  function match_bitapScore(e:int, x:int, loc:int,
                                  score_text_length:int, pattern:String):Number {
    var d:int = Math.abs(loc - x);
    return (e /  (pattern.length as Number) / Match_Balance)
        + (d /  (score_text_length as Number) / (1.0 - Match_Balance));
  }


  /**
   * Initialise the alphabet for the Bitap algorithm.
   * @param pattern The text to encode.
   * @return Hash of character locations.
   */
  public function match_alphabet(pattern:String):Array { //Map<Character, Integer> {
    var s:Array = new Array();//HashMap<Character, Integer>();
    var char_pattern:Array = pattern.split("");
    for each (var c:String in char_pattern) {
      s[c] = 0;
    }
    var i:int = 0;
    for each (var c:String in char_pattern) {
      s[c] = s[c] | (1 << (pattern.length - i - 1));
      i++;
    }
    return s;
  }


  //  PATCH FUNCTIONS


  /**
   * Increase the context until it is unique,
   * but don't let the pattern expand beyond Match_MaxBits.
   * @param patch The patch to grow.
   * @param text Source text.
   */
  public function patch_addContext(patch:Patch, text:String):void {
    var pattern:String = text.substring(patch.start2, patch.start2 + patch.length1);
    var padding:int = 0;
    // Increase the context until we're unique (but don't let the pattern
    // expand beyond Match_MaxBits).
    while (text.indexOf(pattern) != text.lastIndexOf(pattern)
        && pattern.length < Match_MaxBits - Patch_Margin - Patch_Margin) {
      padding += Patch_Margin;
      pattern = text.substring(Math.max(0, patch.start2 - padding),
          Math.min(text.length, patch.start2 + patch.length1 + padding));
    }
    // Add one chunk for good luck.
    padding += Patch_Margin;
    // Add the prefix.
    var prefix:String = text.substring(Math.max(0, patch.start2 - padding),
        patch.start2);
    if (prefix.length != 0) {
      patch.diffs.unshift(new Diff(Operation.EQUAL, prefix));
    }
    // Add the suffix.
    var suffix:String = text.substring(patch.start2 + patch.length1,
        Math.min(text.length, patch.start2 + patch.length1 + padding));
    if (suffix.length != 0) {
      patch.diffs.push(new Diff(Operation.EQUAL, suffix));
    }

    // Roll back the start points.
    patch.start1 -= prefix.length;
    patch.start2 -= prefix.length;
    // Extend the lengths.
    patch.length1 += prefix.length + suffix.length;
    patch.length2 += prefix.length + suffix.length;
  }


  /**
   * Compute a list of patches to turn text1 into text2.
   * A set of diffs will be computed.
   * @param text1 Old text.
   * @param text2 New text.
   * @return LinkedList of Patch objects.
   */
  public function patch_make22(text1:String, text2:String):Array {// LinkedList<Patch> {
    // No diffs provided, compute our own.
    var diffs:Array = diff_main2(text1, text2, true); // LinkedList<Diff>
    if (diffs.length > 2) {
      diff_cleanupSemantic(diffs);
      diff_cleanupEfficiency(diffs);
    }
    return patch_make2(text1, diffs);
  }


  /**
   * Compute a list of patches to turn text1 into text2.
   * text1 will be derived from the provided diffs.
   * @param diffs Array of diff tuples for text1 to text2.
   * @return LinkedList of Patch objects.
   */
  public function patch_make(diffs:Array /*LinkedList<Diff>*/):Array { // was LinkedList<Patch> {
    // No origin string provided, compute our own.
    var text1:String = diff_text1(diffs);
    return patch_make2(text1, diffs);
  }


  /**
   * Compute a list of patches to turn text1 into text2.
   * text2 is ignored, diffs are the delta between text1 and text2.
   * @param text1 Old text
   * @param text2 Ignored.
   * @param diffs Array of diff tuples for text1 to text2.
   * @return LinkedList of Patch objects.
   * @deprecated Prefer patch_make(String text1, LinkedList<Diff> diffs).
   */
  public function patch_make3(text1:String, text2:String,
      diffs:Array /*LinkedList<Diff>*/):Array { // was LinkedList<Patch> {
    return patch_make2(text1, diffs);
  }

  /**
   * Compute a list of patches to turn text1 into text2.
   * text2 is not provided, diffs are the delta between text1 and text2.
   * @param text1 Old text.
   * @param diffs Array of diff tuples for text1 to text2.
   * @return LinkedList of Patch objects.
   */
  public function patch_make2(text1:String, diffs:Array /*LinkedList<Diff>*/):Array { // was LinkedList<Patch> {
    var patches:Array = new Array();//LinkedList<Patch>();
    if (diffs.length == 0) {
      return patches;  // Get rid of the null case.
    }
    var patch:Patch = new Patch();
    var char_count1:int = 0;  // Number of characters into the text1 string.
    var char_count2:int = 0;  // Number of characters into the text2 string.
    // Start with text1 (prepatch_text) and apply the diffs until we arrive at
    // text2 (postpatch_text). We recreate the patches one by one to determine
    // context info.
    var prepatch_text:String = text1;
    var postpatch_text:String = text1;
    for each (var aDiff:Diff in diffs) {
      if (patch.diffs.length == 0 && aDiff.operation != Operation.EQUAL) {
        // A new patch starts here.
        patch.start1 = char_count1;
        patch.start2 = char_count2;
      }

      switch (aDiff.operation) {
      case Operation.INSERT:
        patch.diffs.push(aDiff);
        patch.length2 += aDiff.text.length;
        postpatch_text = postpatch_text.substring(0, char_count2)
            + aDiff.text + postpatch_text.substring(char_count2);
        break;
      case Operation.DELETE:
        patch.length1 += aDiff.text.length;
        patch.diffs.push(aDiff);
        postpatch_text = postpatch_text.substring(0, char_count2)
            + postpatch_text.substring(char_count2 + aDiff.text.length);
        break;
      case Operation.EQUAL:
        if (aDiff.text.length <= 2 * Patch_Margin
            && !patch.diffs.length == 0 && aDiff != diffs[diffs.length-1]) {
          // Small equality inside a patch.
          patch.diffs.push(aDiff);
          patch.length1 += aDiff.text.length;
          patch.length2 += aDiff.text.length;
        }

        if (aDiff.text.length >= 2 * Patch_Margin) {
          // Time for a new patch.
          if (!patch.diffs.length == 0) {
            patch_addContext(patch, prepatch_text);
            patches.push(patch);
            patch = new Patch();
            prepatch_text = postpatch_text;
          }
        }
        break;
      }

      // Update the current character count.
      if (aDiff.operation != Operation.INSERT) {
        char_count1 += aDiff.text.length;
      }
      if (aDiff.operation != Operation.DELETE) {
        char_count2 += aDiff.text.length;
      }
    }
    // Pick up the leftover patch if not empty.
    if (!patch.diffs.length == 0) {
      patch_addContext(patch, prepatch_text);
      patches.push(patch);
    }

    return patches;
  }


  /**
   * Given an array of patches, return another array that is identical.
   * @param patches Array of patch objects.
   * @return Array of patch objects.
   */
  public function patch_deepCopy(patches:Array /*LinkedList<Patch>*/):Array { // was LinkedList<Patch> {
    var patchesCopy:Array = new Array();//LinkedList<Patch>();
    for each (var aPatch:Patch in patches) {
      var patchCopy:Patch = new Patch();
      for each (var aDiff:Diff in aPatch.diffs) {
        var diffCopy:Diff = new Diff(aDiff.operation, aDiff.text);
        patchCopy.diffs.push(diffCopy);
      }
      patchCopy.start1 = aPatch.start1;
      patchCopy.start2 = aPatch.start2;
      patchCopy.length1 = aPatch.length1;
      patchCopy.length2 = aPatch.length2;
      patchesCopy.push(patchCopy);
    }
    return patchesCopy;
  }


  /**
   * Merge a set of patches onto the text.  Return a patched text, as well
   * as an array of true/false values indicating which patches were applied.
   * @param patches Array of patch objects
   * @param text Old text.
   * @return Two element Object array, containing the new text and an array of
   *      boolean values.
   */
  public function patch_apply(patches:Array /*LinkedList<Patch>*/, text:String):Array { // was Object[] {
    if (patches.length == 0) {
      return [text, new Array()]; //new Object[]{text, boolean[0]}
    }

    // Deep copy the patches so that no changes are made to originals.
    patches = patch_deepCopy(patches);

    var nullPadding:String = this.patch_addPadding(patches);
    text = nullPadding + text + nullPadding;
    patch_splitMax(patches);

    var x:int = 0;
    // delta keeps track of the offset between the expected and actual location
    // of the previous patch.  If there are patches expected at positions 10 and
    // 20, but the first patch was found at 12, delta is 2 and the second patch
    // has an effective expected position of 22.
    var delta:int = 0;
    var results:Array = new Array();//boolean[patches.size()];
    var expected_loc:int, start_loc:int;
    var text1:String, text2:String;
    var index1:int, index2:int;
    for each (var aPatch:Patch in patches) {
      expected_loc = aPatch.start2 + delta;
      text1 = diff_text1(aPatch.diffs);
      start_loc = match_main(text, text1, expected_loc);
      if (start_loc == -1) {
        // No match found.  :(
        results[x] = false;
      } else {
        // Found a match.  :)
        results[x] = true;
        delta = start_loc - expected_loc;
        text2 = text.substring(start_loc,
            Math.min(start_loc + text1.length, text.length));
        if (text1 == text2) {
          // Perfect match, just shove the replacement text in.
          text = text.substring(0, start_loc) + diff_text2(aPatch.diffs)
              + text.substring(start_loc + text1.length);
        } else {
          // Imperfect match.  Run a diff to get a framework of equivalent
          // indicies.
          var diffs:Array = diff_main2(text1, text2, false); //LinkedList<Diff>
          diff_cleanupSemanticLossless(diffs);
          index1 = 0;
          for each (var aDiff:Diff in aPatch.diffs) {
            if (aDiff.operation != Operation.EQUAL) {
              index2 = diff_xIndex(diffs, index1);
              if (aDiff.operation == Operation.INSERT) {
                // Insertion
                text = text.substring(0, start_loc + index2) + aDiff.text
                    + text.substring(start_loc + index2);
              } else if (aDiff.operation == Operation.DELETE) {
                // Deletion
                text = text.substring(0, start_loc + index2)
                    + text.substring(start_loc + diff_xIndex(diffs,
                    index1 + aDiff.text.length));
              }
            }
            if (aDiff.operation != Operation.DELETE) {
              index1 += aDiff.text.length;
            }
          }
        }
      }
      x++;
    }
    // Strip the padding off.
    text = text.substring(nullPadding.length, text.length
        - nullPadding.length);
    return [text, results]; //new Object[]{
  }

  /**
   * Add some padding on text start and end so that edges can match something.
   * @param patches Array of patch objects.
   * @return The padding string added to each side.
   */
  public function patch_addPadding(patches:Array /*LinkedList<Patch>*/):String {
    var diffs:Array;
    var nullPadding:String = "";
    for (var x:int = 0; x < this.Patch_Margin; x++) {
      nullPadding += String.fromCharCode(x);
    }

    // Bump all the patches forward.
    for each (var aPatch:Patch in patches) {
      aPatch.start1 += nullPadding.length;
      aPatch.start2 += nullPadding.length;
    }

    // Add some padding on start of first diff.
    var patch:Patch = patches[0];
    diffs = patch.diffs;
    if (diffs.length == 0 || diffs[0].operation != Operation.EQUAL) {
      // Add nullPadding equality.
      diffs.unshift(new Diff(Operation.EQUAL, nullPadding));
      patch.start1 -= nullPadding.length;  // Should be 0.
      patch.start2 -= nullPadding.length;  // Should be 0.
      patch.length1 += nullPadding.length;
      patch.length2 += nullPadding.length;
    } else if (nullPadding.length > diffs[0].text.length) {
      // Grow first equality.
      var firstDiff:Diff = diffs[0];
      var extraLength:int = nullPadding.length - firstDiff.text.length;
      firstDiff.text = nullPadding.substring(firstDiff.text.length)
          + firstDiff.text;
      patch.start1 -= extraLength;
      patch.start2 -= extraLength;
      patch.length1 += extraLength;
      patch.length2 += extraLength;
    }

    // Add some padding on end of last diff.
    patch = patches[patches.length-1];
    diffs = patch.diffs;
    if (diffs.length == 0 || diffs[diffs.length-1].operation != Operation.EQUAL) {
      // Add nullPadding equality.
      diffs.push(new Diff(Operation.EQUAL, nullPadding));
      patch.length1 += nullPadding.length;
      patch.length2 += nullPadding.length;
    } else if (nullPadding.length > diffs[diffs.length-1].text.length) {
      // Grow last equality.
      var lastDiff:Diff = diffs[diffs.length-1];
      var extraLength:int = nullPadding.length - lastDiff.text.length;
      lastDiff.text += nullPadding.substring(0, extraLength);
      patch.length1 += extraLength;
      patch.length2 += extraLength;
    }

    return nullPadding;
  }

  /**
   * Look through the patches and break up any which are longer than the
   * maximum limit of the match algorithm.
   * @param patches LinkedList of Patch objects.
   */
  public function patch_splitMax(patches:Array /*LinkedList<Patch>*/):void {
    var patch_size:int;
    var precontext:String, postcontext:String;
    var patch:Patch;
    var start1:int, start2:int;
    var empty:Boolean;
    var diff_type:Operation;
    var diff_text:String;
    var pointer:ArrayIterator = new ArrayIterator(patches); //.listIterator();
    var bigpatch:Patch = pointer.hasNext() ? pointer.next() : null;
    while (bigpatch != null) {
      if (bigpatch.length1 <= Match_MaxBits) {
        bigpatch = pointer.hasNext() ? pointer.next() : null;
        continue;
      }
      // Remove the big old patch.
      pointer.remove();
      patch_size = Match_MaxBits;
      start1 = bigpatch.start1;
      start2 = bigpatch.start2;
      precontext = "";
      while (bigpatch.diffs.length != 0) {
        // Create one of several smaller patches.
        patch = new Patch();
        empty = true;
        patch.start1 = start1 - precontext.length;
        patch.start2 = start2 - precontext.length;
        if (precontext.length != 0) {
          patch.length1 = patch.length2 = precontext.length;
          patch.diffs.push(new Diff(Operation.EQUAL, precontext));
        }
        while (bigpatch.diffs.length != 0
            && patch.length1 < patch_size - Patch_Margin) {
          diff_type = bigpatch.diffs[0].operation;
          diff_text = bigpatch.diffs[0].text;
          if (diff_type == Operation.INSERT) {
            // Insertions are harmless.
            patch.length2 += diff_text.length;
            start2 += diff_text.length;
            patch.diffs.push(bigpatch.diffs.shift());
            empty = false;
          } else {
            // Deletion or equality.  Only take as much as we can stomach.
            diff_text = diff_text.substring(0, Math.min(diff_text.length,
                patch_size - patch.length1 - Patch_Margin));
            patch.length1 += diff_text.length;
            start1 += diff_text.length;
            if (diff_type == Operation.EQUAL) {
              patch.length2 += diff_text.length;
              start2 += diff_text.length;
            } else {
              empty = false;
            }
            patch.diffs.push(new Diff(diff_type, diff_text));
            if (diff_text == bigpatch.diffs[0].text) {
              bigpatch.diffs.shift();
            } else {
              bigpatch.diffs[0].text = bigpatch.diffs[0].text
                  .substring(diff_text.length);
            }
          }
        }
        // Compute the head context for the next patch.
        precontext = diff_text2(patch.diffs);
        precontext = precontext.substring(Math.max(0, precontext.length
            - Patch_Margin));
        // Append the end context for this patch.
        if (diff_text1(bigpatch.diffs).length > Patch_Margin) {
          postcontext = diff_text1(bigpatch.diffs).substring(0, Patch_Margin);
        } else {
          postcontext = diff_text1(bigpatch.diffs);
        }
        if (postcontext.length != 0) {
          patch.length1 += postcontext.length;
          patch.length2 += postcontext.length;
          if (!patch.diffs.length == 0
              && patch.diffs[patch.diffs.length-1].operation == Operation.EQUAL) {
            patch.diffs[patch.diffs.length-1].text += postcontext;
          } else {
            patch.diffs.push(new Diff(Operation.EQUAL, postcontext));
          }
        }
        if (!empty) {
          pointer.add(patch);
        }
      }
      bigpatch = pointer.hasNext() ? pointer.next() : null;
    }
  }


  /**
   * Take a list of patches and return a textual representation.
   * @param patches List of Patch objects.
   * @return Text representation of patches.
   */
  public function patch_toText(patches:Array /*List<Patch>*/):String {
    var text:String = "";//new StringBuilder();
    for each (var aPatch:Patch in patches) {
      text = text.concat(aPatch);
    }
    return text.toString();
  }


  /**
   * Parse a textual representation of patches and return a List of Patch
   * objects.
   * @param textline Text representation of patches.
   * @return List of Patch objects.
   * @throws IllegalArgumentException If invalid input.
   */
  public function patch_fromText(textline:String):Array // was List<Patch>
      {//throws IllegalArgumentException {
    var patches:Array = new Array();//LinkedList<Patch>();
    if (textline.length == 0) {
      return patches;
    }
    var textList:Array /*List<>*/= textline.split("\n");
    var text:Array = new Array().concat(textList);//LinkedList<String>(textList);
    var patch:Patch;
    var sign:String; // char
    var line:String;
    while (text.length != 0) {
      var patchHeader:RegExp = new RegExp("^@@ -(\\d+),?(\\d*) \\+(\\d+),?(\\d*) @@", "g");
      var match = patchHeader.exec(text[0]);
      if (match == null || match.length == 0) {
//        throw new IllegalArgumentException(
            trace("Invalid patch string: " + text[0]);
      }
      patch = new Patch();
      patches.push(patch);
      patch.start1 = int(match[1]); // Integer.parseInt()
      if (match[2].length == 0) {
        patch.start1--;
        patch.length1 = 1;
      } else if (match[2] == "0") {
        patch.length1 = 0;
      } else {
        patch.start1--;
        patch.length1 = int(match[2]); //Integer.parseInt()
      }

      patch.start2 = int(match[3]); // Integer.parseInt()
      if (match[4].length == 0) {
        patch.start2--;
        patch.length2 = 1;
      } else if (match[4] == "0") {
        patch.length2 = 0;
      } else {
        patch.start2--;
        patch.length2 = int(match[4]); // Integer.parseInt()
      }
      text.shift();

      while (text.length != 0) {
        try {
          sign = text[0].charAt(0);
        } catch (e) {
          // Blank line?  Whatever.
          text.shift();
          continue;
        }
        line = text[0].substring(1);
        var pattern:RegExp = new RegExp("+", "g");
        line = line.replace(pattern, "%2B");  // decode would change all "+" to " "
        try {
			line = unescape(line);
        } catch (e) {
          // Not likely on modern system.
          throw new Error("This system does not support UTF-8 OR Illegal escape in patch_fromText", e);
        }
        if (sign == '-') {
          // Deletion.
          patch.diffs.push(new Diff(Operation.DELETE, line));
        } else if (sign == '+') {
          // Insertion.
          patch.diffs.push(new Diff(Operation.INSERT, line));
        } else if (sign == ' ') {
          // Minor equality.
          patch.diffs.push(new Diff(Operation.EQUAL, line));
        } else if (sign == '@') {
          // Start of next patch.
          break;
        } else {
          // WTF?
//          throw new IllegalArgumentException(
              trace("Invalid patch mode '" + sign + "' in: " + line);
        }
        text.shift();
      }
    }
    return patches;
  }

  /**
   * Unescape selected chars for compatability with JavaScript's encodeURI.
   * In speed critical applications this could be dropped since the
   * receiving application will certainly decode these fine.
   * Note that this function is case-sensitive.  Thus "%3f" would not be
   * unescaped.  But this is ok because it is only called with the output of
   * URLEncoder.encode which returns uppercase hex.
   * 
   * Example: "%3F" -> "?", "%24" -> "$", etc.
   * 
   * @param str The string to escape.
   * @return The escaped string.
   */
      function unescapeForEncodeUriCompatability(str:String):String {
  	    var pat21:RegExp = new RegExp("%21", "g");
  	    var pat7E:RegExp = new RegExp("%7E", "g");
  	    var pat27:RegExp = new RegExp("%27", "g");
  	    var pat28:RegExp = new RegExp("%28", "g");
  	    var pat29:RegExp = new RegExp("%29", "g");
  	    var pat3B:RegExp = new RegExp("%3B", "g");
  	    var pat2F:RegExp = new RegExp("%2F", "g");
  	    var pat3F:RegExp = new RegExp("%3F", "g");
  	    var pat3A:RegExp = new RegExp("%3A", "g");
  	    var pat40:RegExp = new RegExp("%40", "g");
  	    var pat26:RegExp = new RegExp("%26", "g");
  	    var pat3D:RegExp = new RegExp("%3D", "g");
  	    var pat2B:RegExp = new RegExp("%2B", "g");
  	    var pat24:RegExp = new RegExp("%24", "g");
  	    var pat2C:RegExp = new RegExp("%2C", "g");
  	    var pat23:RegExp = new RegExp("%23", "g");
  	    
	    return str.replace(pat21, "!").replace(pat7E, "~")
	        .replace(pat27, "'").replace(pat28, "(").replace(pat29, ")")
	        .replace(pat3B, ";").replace(pat2F, "/").replace(pat3F, "?")
	        .replace(pat3A, ":").replace(pat40, "@").replace(pat26, "&")
	        .replace(pat3D, "=").replace(pat2B, "+").replace(pat24, "$")
	        .replace(pat2C, ",").replace(pat23, "#");
	  }
		

	}
}