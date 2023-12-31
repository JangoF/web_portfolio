import * as THREE from 'three';
import { Planet } from './Planet';
import { Ship } from './Ship';
import { Moon } from './Moon';
import { Dust } from './Dust';
// import { SkySphere } from './SkySphere';

class App {
  private renderer: THREE.WebGLRenderer;
  private scene: THREE.Scene;
  private camera: THREE.PerspectiveCamera;

  private planet: Planet;
  private ship: Ship;
  private moon: Moon;
  private dust: Dust;
  private dustContainer: THREE.Group;
  // private sky: SkySphere;
  private shipContainer: THREE.Group;
  private directionalLight: THREE.DirectionalLight;

  constructor() {
    {
      this.renderer = new THREE.WebGLRenderer();
      this.renderer.setSize(window.innerWidth, window.innerHeight);
      // this.renderer.setPixelRatio(window.devicePixelRatio / 4);
      this.renderer.setClearColor(0x10181F);

      document.body.appendChild(this.renderer.domElement);
      window.addEventListener('resize', this.onWindowResize);

      this.scene = new THREE.Scene();
      this.camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 1, 1000);
    }

    {
      this.shipContainer = new THREE.Group();
      this.shipContainer.rotation.y = 0.6;
      this.scene.add(this.shipContainer);
    }

    {
      this.planet = new Planet(20);
      this.scene.add(this.planet);
    }

    {
      this.moon = new Moon(10);
      this.moon.position.set(0, 120, 400);
      this.scene.add(this.moon);
    }

    {
      this.dustContainer = new THREE.Group();
      this.shipContainer.add(this.dustContainer);
      this.dustContainer.rotation.x = 0.3;

      this.dust = new Dust();
      this.dust.position.set(-100, 0, 0);
      this.dustContainer.add(this.dust);
    }

    // {
    //   this.sky = new SkySphere(50, 10000);
    //   this.scene.add(this.sky);
    // }


    this.shipContainer.add(this.camera);

    this.ship = new Ship();
    this.ship.position.z = this.planet.radius + 100;
    this.ship.rotation.y = -Math.PI / 4;
    this.ship.rotation.x = 0.4;
    this.shipContainer.add(this.ship);


    this.camera.position.copy(this.ship.position);
    this.camera.position.z += 6;
    this.camera.position.x -= 2.5;

    this.camera.lookAt(this.ship.position.clone());

    this.directionalLight = new THREE.DirectionalLight(0xffffff, 1);
    this.directionalLight.position.set(1, 0.5, -1);

    const directionalLightHelper = new THREE.DirectionalLightHelper(this.directionalLight, 0.5);

    this.scene.add(this.directionalLight);
    this.scene.add(directionalLightHelper);
  }

  private onWindowResize = () => {
    const newWidth = window.innerWidth;
    const newHeight = window.innerHeight;

    this.camera.aspect = newWidth / newHeight;
    this.camera.updateProjectionMatrix();

    this.renderer.setSize(newWidth, newHeight);
  }

  private animate = () => {
    requestAnimationFrame(this.animate);

    {
      const nowTime = Date.now() * 0.0001;
      this.shipContainer.rotation.y = nowTime;
    }

    {

      const nowTime = Date.now() * 0.001;
      this.dust.rotation.y = -nowTime;
    }

    {
      const nowTime_0 = Date.now() * 0.0002;
      const nowTime_1 = Date.now() * 0.0005;
      
      const shipWorldPosition = new THREE.Vector3();
      this.ship.getWorldPosition(shipWorldPosition);

      this.camera.position.copy(this.ship.position);
      this.camera.position.x += Math.cos(nowTime_0);
      this.camera.position.y += 2 + Math.cos(nowTime_1) * 0.5;
      this.camera.position.z += 12 + Math.sin(nowTime_1) * 4;

      const scale = 0.15;
      const offset = new THREE.Vector3(Math.cos(nowTime_0) * scale, Math.cos(nowTime_0) * scale, Math.cos(nowTime_0) * scale);
      this.camera.lookAt(new THREE.Vector3());
    }

    this.planet.update(this.directionalLight.position.clone());
    this.ship.update(this.directionalLight.position.clone());

    this.renderer.render(this.scene, this.camera);
  }

  public start() {
    this.animate();
  }
}

const app = new App();
app.start();
