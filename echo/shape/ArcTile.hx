package echo.shape;

import echo.data.Data.CollisionData;
import echo.math.Vector2;
import echo.util.Bezier;

class ArcTile extends Rect {
  public var arc:Bezier;
  public var controlPoints:Array<Vector2>;

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
      inverted:Bool = false, curvature:Float = -1):ArcTile {
    var arcTile = pool.get();
    // trace('rot in: $rotation');

    arcTile.set(x, y, width, height, rotation, scale_x, scale_y);
    arcTile.pooled = false;

    // trace('arcTile rot: ${arcTile.rotation}');

    // Positive curvature is convex, negative is concave
    var controlPoints = [
      new Vector2(-width / 2, -height / 2),
      new Vector2(-width / 2, 0),
      new Vector2(0, y + height / 2),
      new Vector2(width / 2, height / 2),
    ];

    var angle = 45 + curvature * 45;
    if (curvature == 0) {
      controlPoints[1].rotate(0 * (Math.PI / 180), controlPoints[0]);
      controlPoints[2].rotate(40 * (Math.PI / 180), controlPoints[3]);
    }
    else {
      controlPoints[1].rotate(-angle * (Math.PI / 180), controlPoints[0]);
      controlPoints[2].rotate(angle * (Math.PI / 180), controlPoints[3]);
    }
    arcTile.controlPoints = controlPoints;
    arcTile.arc = new Bezier();
    for (cp in controlPoints) {
      arcTile.arc.add_control_point(cp.x, cp.y);
    }

    return arcTile;
  }

  override function on_dirty(t) {
    super.on_dirty(t);

    var pos = get_position();

    // trace(transform);
    // trace(local_rotation);
    // trace(rotation);

    for (i in 0...controlPoints.length) {
      var p:Vector2 = controlPoints[i].clone().rotate(local_rotation);
      if (transformed_rect != null) {
        trace('tRect locRot: ${transformed_rect.local_rotation}');

        // p = controlPoints[i].clone().rotate(-Math.PI / 2);
        p = controlPoints[i].rotate(transformed_rect.local_rotation * Math.PI / 180);
        // arc.set_control_point(i, p.x, p.y,);
      }
      // arc.get
      arc.set_control_point(i, p.x, p.y, false);
    }
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
    var ccwBound:Vector2;
    var cwBound:Vector2;
    var circleCheck:Vector2;

    if (transformed_rect != null && rotation != 0) {
      var bl = transformed_rect.vertices[3];
      var tl = transformed_rect.vertices[0];
      var br = transformed_rect.vertices[2];

      ccwBound = tl - bl;
      cwBound = br - bl;
      circleCheck = cCenter - bl;
    }
    else {
      var bl = new Vector2(left, bottom);
      var tl = new Vector2(left, top);
      var br = new Vector2(right, bottom);

      ccwBound = tl - bl;
      cwBound = br - bl;
      circleCheck = cCenter - bl;
    }

    // if circle center is outside quadrant, collide against outer rect.
    // TODO: This behaves oddly at the corners.
    // if (circleCheck.cross(ccwBound) > 0 || circleCheck.cross(cwBound) < 0) {
    //   return super.collide_circle(c, flip);
    // }

    // otherwise collide against arc
    var closestAB:Vector2 = null;
    var closestAC:Vector2 = null;
    var closestPoint:Vector2 = null;
    var distVecFinal:Vector2 = null;
    var abNormFinal:Vector2 = null;
    var minDist:Float = Math.POSITIVE_INFINITY;

    var tilePos = get_position();

    var i = -1;
    for (l in arc.lines) {
      i++;
      var start = l.start + tilePos;
      var end = l.end + tilePos;
      var ab = end - start;
      var ac = cCenter - start; // TODO: We might need to adjust for the tile position
      var abUnit = ab.normal;
      // Project circle center onto the line segment
      var proj = ac.dot(abUnit);
      var projClamped = Math.max(0, Math.min(ab.length, proj));
      var closestP = start + (abUnit * projClamped);
      var distVec = closestP - cCenter;
      var dist = distVec.length;
      if (dist < minDist) {
        minDist = dist;
        closestAB = ab;
        closestAC = ac;
        closestPoint = closestP;
        distVecFinal = distVec;
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
    //   distVecFinal *= -1;
    //   overlap = minDist + c.radius;
    //   // trace('cross: ${closestAC.cross(closestAB)}');
    //   // trace('AB: $closestAB');
    //   // trace('AC: $closestAC');
    //   // trace('dot: ${closestAC.dot(closestAB)}');
    //   // trace('bump');
    // }
    // else
    if (minDist > c.radius) {
      return null;
    }

    // trace('resolving with $overlap @ $distVecFinal');
    // abNormFinal = abNormFinal * -1;

    distVecFinal.normalize();
    var col = CollisionData.get(Math.abs(minDist - c.radius), distVecFinal.x, distVecFinal.y);
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
