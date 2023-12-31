import * as THREE from 'three';

export class SkySphere extends THREE.Group {
  constructor(radius: number, starCount: number) {
    super();
    this.generateStars(radius, starCount);
  }

  private generateStars(radius: number, starCount: number) {
    const geometry = new THREE.BufferGeometry();
    const material = new THREE.PointsMaterial({ color: 0xffffff, size: 0.02 });

    const positions = new Float32Array(starCount * 3);

    for (let i = 0; i < starCount; i++) {
      const phi = Math.random() * Math.PI * 2;
      const theta = Math.random() * Math.PI;

      const x = radius * Math.sin(theta) * Math.cos(phi);
      const y = radius * Math.sin(theta) * Math.sin(phi);
      const z = radius * Math.cos(theta);

      positions[i * 3] = x;
      positions[i * 3 + 1] = y;
      positions[i * 3 + 2] = z;
    }

    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    this.add(new THREE.Points(geometry, material));
  }
}
