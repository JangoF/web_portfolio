import * as THREE from 'three';

import vertexShader from './shaders/dust.vertex.glsl';
import fragmentShader from './shaders/dust.fragment.glsl';

export class Dust extends THREE.Group {

  constructor() {
    super();

    // Создаем геометрию тора
    // const torusGeometry = new THREE.TorusGeometry(110, 30, 16, 100);
    // // torusGeometry.rotateX(Math.PI);
    // torusGeometry.rotateX(Math.PI / 2);

    // Генерируем рандомные точки в трехмерном пространстве
    const numPoints = 1000;
    const pointsGeometry = new THREE.BufferGeometry();
    const positions = new Float32Array(numPoints * 3);

    for (let i = 0; i < numPoints; i++) {
      const phi = Math.random() * Math.PI * 2;
      const theta = Math.random() * Math.PI * 2;
      const radius = Math.random() * 4; // Радиус точки внутри тора

      const x = (5 + radius * Math.cos(theta)) * Math.cos(phi);
      const y = (5 + radius * Math.cos(theta)) * Math.sin(phi);
      const z = radius * Math.sin(theta);

      positions[i * 3] = x;
      positions[i * 3 + 1] = y;
      positions[i * 3 + 2] = z;
    }

    pointsGeometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
    pointsGeometry.rotateX(Math.PI / 2);
    pointsGeometry.scale(20, 20, 20);


    // Создаем материал для точек
    // const pointsMaterial = new THREE.PointsMaterial({ color: 0x00ff00, size: 0.25 });

    // Создаем объект THREE.Points с геометрией и материалом
    // const points = new THREE.Points(torusGeometry, pointsMaterial);

    const pointsMaterial = new THREE.ShaderMaterial({
      vertexShader: vertexShader,
      fragmentShader: fragmentShader,
    });

    pointsMaterial.transparent = true;
    const points = new THREE.Points(pointsGeometry, pointsMaterial);
    
    // Добавляем объект в сцену
    this.add(points);
  }
}































