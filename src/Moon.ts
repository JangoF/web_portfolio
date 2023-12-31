import * as THREE from 'three';

export class Moon extends THREE.Group {
  private _radius: number;

  constructor(radius: number) {
    super();
    this._radius = radius;

    const geometry = new THREE.SphereGeometry(this._radius, 64, 32);
    const material = new THREE.MeshLambertMaterial({ color: 0xcccccc });
    this.add(new THREE.Mesh(geometry, material));
  }

  public get radius(): number {
    return this._radius;
  }
}
