import * as THREE from 'three';

import vertexShader from './shaders/atmosphere.vertex.glsl';
import fragmentShader from './shaders/atmosphere.fragment.glsl';

export class Planet extends THREE.Group {
  private _radius: number;
  private atmosphereMaterial: THREE.ShaderMaterial;

  constructor(radius: number) {
    super();
    this._radius = radius;

    const geometry = new THREE.SphereGeometry(this._radius * 1.04, 16, 8);
    this.atmosphereMaterial = new THREE.ShaderMaterial({
      defines: { 
        PI: Math.PI, 
        INFINITY: "1e20",

        ATMOSPHERE_RADIUS: String(this._radius) + ".0",
        PLANET_RADIUS: String(this._radius * 0.8) + ".0",

        AVANGE_DENSITY_RAY: 1.2,
        AVANGE_DENSITY_MIE: 0.5,
      },
      uniforms: {
        sunDirection: { value: new THREE.Vector3() },
      },
      vertexShader: vertexShader,
      fragmentShader: fragmentShader,
    });

    this.atmosphereMaterial.transparent = true;
    this.add(new THREE.Mesh(geometry, this.atmosphereMaterial));
  }

  public get radius(): number {
    return this._radius;
  }

  update(sunDirection: THREE.Vector3) {
    this.atmosphereMaterial.uniforms.sunDirection.value = sunDirection;
    this.atmosphereMaterial.uniformsNeedUpdate = true;
  }
}
