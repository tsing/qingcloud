crypto = require 'crypto'
exports.sign = (data, key, method='sha256') -> 
  hmac = crypto.createHmac method, key
  hmac.update data
  hmac.digest 'base64'
exports.nparam = (key) -> 
  match = /(.+?)\.n\b/.exec key
  match[1] if match
