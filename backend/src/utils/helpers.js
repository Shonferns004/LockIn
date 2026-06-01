import crypto from 'crypto';

export function generateId() {
  return crypto.randomUUID();
}

export function sha256(str) {
  return crypto.createHash('sha256').update(str).digest('hex');
}
