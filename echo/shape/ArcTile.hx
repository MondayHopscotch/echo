package echo.shape;

import echo.data.Data.CollisionData;
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

    // Positive curvature is convex, negative is concave
    var curvature = -1;
    var controlPoints = [
      new Vector2(x - width / 2, y - height / 2),
      new Vector2(x - width / 2, y),
      new Vector2(x, y + height / 2),
      new Vector2(x + width / 2, y + height / 2),
    ];

    var angle = 45 + curvature * 45;
    controlPoints[1].rotate(-angle * (Math.PI / 180), controlPoints[0]);
    controlPoints[2].rotate(angle * (Math.PI / 180), controlPoints[3]);

    arcTile.arc = new Bezier(controlPoints);

    return arcTile;
  }

  override inline function overlaps(s:Shape):Bool {
    // return super.overlaps(s);
    return false;
  }

  override function collides(s:Shape):Null<CollisionData> {
    if (!super.overlaps(s)) {
      return null;
    }
    // return arc.collides(s);
    return null;
  }

  override function collide_rect(r:Rect, flip:Bool = false):Null<CollisionData> {
    return null;
  }

  override function collide_circle(c:Circle, flip:Bool = false):Null<CollisionData> {
    var cCenter = c.get_position();

    var bl = new Vector2(left, bottom);
    var tl = new Vector2(left, top);
    var br = new Vector2(right, bottom);

    var ccwBound = tl - bl;
    var cwBound = br - bl;
    var circleCheck = cCenter - bl;

    // if circle center is outside quadrant, collide against outer rect.
    // TODO: This behaves oddly at the corners.
    if (circleCheck.cross(ccwBound) > 0 || circleCheck.cross(cwBound) < 0) {
      return super.collide_circle(c, flip);
    }

    // otherwise collide against arc
    var closestAB:Vector2 = null;
    var closestAC:Vector2 = null;
    var closestPoint:Vector2 = null;
    var distVecFinal:Vector2 = null;
    var abNormFinal:Vector2 = null;
    var minDist:Float = Math.POSITIVE_INFINITY;

    var tilePos = get_position();

    for (l in arc.lines) {
      var start = l.start + tilePos;
      var end = l.end + tilePos;
      var ab = end - start;
      var ac = cCenter - start; // TODO: We might need to adjust for the tile position
      var abUnit = ab.normal;
      // Project circle center onto the line segment
      var proj = ac.dot(abUnit);
      var projClamped = Math.max(0, Math.min(ab.length, proj));
      var closestP = start + (abUnit * projClamped);
      var distVec = cCenter - closestP;
      var dist = distVec.length;
      if (dist < minDist) {
        minDist = dist;
        closestAB = ab;
        closestAC = ac;
        closestPoint = closestP;
        distVecFinal = distVec;
        abNormFinal = abUnit.rotate_left();
      }
    }

    Main.instance.debug.draw_line(c.x, c.y, closestPoint.x, closestPoint.y, 0xffff00);

    if (minDist == Math.POSITIVE_INFINITY) {
      return null;
    }

    var overlap = Math.abs(minDist - c.radius);

    // TODO: For some reason this cross product doesn't seem to be doing what I'm expecting
    // if (contains(cCenter) && closestAC.cross(closestAB) < 0) {
    //   // Circle center is on the wrong side of the curve. Adjust dist to push it out completely.
    //   // This means push it out by the distance to the center + radius
    //   overlap = minDist + c.radius;
    //   trace('cross: ${closestAC.cross(closestAB)}');
    //   trace('AB: $closestAB');
    //   trace('AC: $closestAC');
    //   trace('dot: ${closestAC.dot(closestAB)}');
    //   trace('bump');
    // }
    // else
    if (minDist > c.radius) {
      return null;
    }

    trace('resolving with overlap of $overlap');
    var col = CollisionData.get(overlap, abNormFinal.x, abNormFinal.y);
    col.sa = flip ? c : this;
    col.sb = flip ? this : c;

    return col;
  }

  override function collide_polygon(p:Polygon, flip:Bool = false):Null<CollisionData> {
    return null;
  }

  override function put() {
    super.put();
    if (!pooled) {
      pooled = true;
      pool.put_unsafe(this);
    }
  }
}
