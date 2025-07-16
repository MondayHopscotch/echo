package echo.shape;

import echo.math.Vector2;
import echo.util.Bezier;

class ArcTile extends Rect {
  public var arc:Bezier;

  inline function new() {
    super();
    local_ex = 0;
    local_ey = 0;
    type = ARC_TILE;
    transform.on_dirty = on_dirty;
  }
  /**
   * Gets an ArcTile from the pool, or creates a new one if none are available. Call `put()` on the ArcTile to place it back in the pool.
   * @param x
   * @param y
   * @param TODO
   * @return ArcTile
   */
  public static inline function get(x:Float = 0, y:Float = 0, width:Float = 1, height:Float = 1, rotation:Float = 0, scale_x:Float = 1, scale_y:Float = 1,
      inverted:Bool = false):ArcTile {
    var arcTile = pool.get();
    arcTile.set(x, y, width, height, rotation, scale_x, scale_y);
    arcTile.pooled = false;

    trace('x: $x, y: $y');
    arcTile.arc = new Bezier([
      new Vector2(x - width / 2, y - height / 2),
      new Vector2(x - width / 2, y),
      new Vector2(x, y + height / 2),
      new Vector2(x + width / 2, y + height / 2),
    ]);

    trace(arcTile.arc);
    return arcTile;
  }

  override function put() {
    super.put();
    if (!pooled) {
      pooled = true;
      pool.put_unsafe(this);
    }
  }
}
