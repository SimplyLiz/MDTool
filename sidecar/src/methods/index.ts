import type { RpcMethods } from '../rpc/methods.js';
import { health } from './health.js';

export const methods: RpcMethods = {
  health: async () => health(),
};
