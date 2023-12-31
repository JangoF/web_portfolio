import * as THREE from 'three';

import vertexShader from './shaders/ship.vertex.glsl';
import fragmentShader from './shaders/ship.fragment.glsl';

export class Ship extends THREE.Group {
  private ship: THREE.ShaderMaterial;
  private timeStart: number;

  constructor() {
    super();

    this.timeStart = Date.now();
    const size = 1.8;
    const geometry = new THREE.SphereGeometry(2, 16, 8);
    // const geometry = new THREE.BoxGeometry(size, size, size);
    this.ship = new THREE.ShaderMaterial({
      defines: { 
        PI: Math.PI, 
        EPSILON: 0.001, 
      },
      uniforms: {
        sunDirection: { value: new THREE.Vector3() },
        u_time: { value: 0.0 },
      },
      vertexShader: vertexShader,
      fragmentShader: fragmentShader,
    });

    this.ship.transparent = true;
    this.add(new THREE.Mesh(geometry, this.ship));
  }

  update(sunDirection: THREE.Vector3) {
    const worldPosition = new THREE.Vector3();
    this.getWorldPosition(worldPosition);

    this.ship.uniforms.sunDirection.value = sunDirection;
    this.ship.uniforms.u_time.value = (Date.now()) - this.timeStart;
    this.ship.uniformsNeedUpdate = true;
  }
}
