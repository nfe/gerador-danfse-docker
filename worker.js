import { DurableObject } from "cloudflare:workers";

const PORT = 8080;
const INSTANCES = 3; // shortcut: roteamento aleatório entre 3 instâncias; trocar por autoscaling quando a Cloudflare liberar.

export class Danfse extends DurableObject {
  async fetch(request) {
    const container = this.ctx.container;
    if (!container.running) {
      container.start({ image: container.images.base, enableInternet: false });
    }
    const port = container.getTcpPort(PORT);
    for (let i = 0; i < 100; i++) {
      try {
        const r = await port.fetch(`http://container/health/ready`);
        if (r.ok) break;
      } catch {}
      await new Promise((ok) => setTimeout(ok, 200));
    }
    container.setInactivityTimeout(10 * 60 * 1000);
    return port.fetch(request);
  }
}

export default {
  fetch(request, env) {
    return env.DANFSE.getByName(`instance-${Math.floor(Math.random() * INSTANCES)}`).fetch(request);
  },
};
