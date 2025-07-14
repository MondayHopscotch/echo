package echo.shape;

import echo.util.Poolable;

class ArcTile extends Shape implements Poolable {
  override function put() {
    super.put();
    if (!pooled) {
      pooled = true;
      pool.put_unsafe(this);
    }
  }
}
