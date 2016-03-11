extend = require 'extend'
request = require 'request'
querystring = require 'querystring'

util = require './util'
config = require '../config'

class QingCloud
  constructor: (@accessKeyId, @secretAccessKey, @config=config) ->
    @staticParams =
      access_key_id: @accessKeyId
      version: @config.version
      signature_method: @config.signature_method
      signature_version: @config.signature_version
    @initActions()
  initActions: () ->
    @initAction action, config for action, config of @config.actions
  initAction: (action, config) ->
    @[action] = (params, cb) ->
      [params, cb] = [{}, params] if params instanceof Function
      for key in config.required
        if _key = util.nparam key
          return cb new Error "参数: #{key} 必须是一个数组" if !Array.isArray params[_key]
        else
          return cb new Error "缺少必须的参数 #{key}" if !params[key]?
      params.action = action
      @request params, cb
  request: (params, cb) ->
    qs = querystring.stringify @formatParams params
    request url:"#{@config.host}?#{qs}", json:true, (err, res, body) =>
      return cb err if err?
      return cb new Error "API 请求错误: [#{res.statusCode}]" if res.statusCode isnt 200
      ret_code = parseInt body.ret_code
      if ret_code isnt 0
        qcError = @config.errors[ret_code]
        return cb new Error if !qcError?
          "接口调用错误: 未知返回代码 #{ret_code}"
        else
          reason = if qcError.client then "请求错误" else "服务器错误"
          "接口调用错误: #{reason} #{ret_code}\n#{qcError.type}\n#{qcError.tip}\n#{body.message}"
      cb null, body
  formatParams: (params) ->
    _params = time_stamp: new Date().toISOString()
    for param, value of params
      if Array.isArray value
        value.forEach (ele, i) ->
          if typeof ele is 'string'
            _params["#{param}.#{i}"] = ele
          else
            _params["#{param}.#{i}.#{k}"] = v for k, v of ele
      else
        _params[param] = value
    @sign extend _params, @staticParams
  sign: (params) ->
    params = Object.keys(params)
      .map (key) -> key: key, val: params[key]
      .sort (lhv, rhv) -> lhv.key.localeCompare rhv.key
      .reduce (total, ele) ->
        total[ele.key] = ele.val
        total
      , {}
    unsigned = "GET\n/iaas/\n#{querystring.stringify params}"
    params.signature = util.sign unsigned, @secretAccessKey
    params
  handleActionError: (err, qcError) ->
    throw err if err?
    return console.error "未知错误" if !qcError?
    errMsg = if qcError.client then "请求错误" else "服务器错误"
    console.error "#{errMsg}\n#{qcError.type}\n#{qcError.tip}"

module.exports = QingCloud
