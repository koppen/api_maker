import BaseModel from "./BaseModel"
import ModelsResponseReader from "./ModelsResponseReader"
import qs from "qs"
import Result from "./Result"

export default class Collection {
  constructor(args) {
    this.args = args
    this.includes = args.includes
    this.params = args.params
    this.ransackOptions = args.ransack || {}
  }

  each(callback) {
    this.toArray().then((array) => {
      for(var model in array) {
        callback.call(model)
      }
    })
  }

  first() {
    return new Promise((resolve, reject) => {
      this.toArray().then((models) => {
        resolve(models[0])
      })
    })
  }

  limit(amount) {
    this.limit = amount
    return this
  }

  loaded() {
    if (!(this.args.reflectionName in this.args.model.relationshipsCache)) {
      var model = this.args.model
      throw `${this.args.reflectionName} hasnt been loaded yet`
    }

    return this.args.model.relationshipsCache[this.args.reflectionName]
  }

  preload(args) {
    this.includes = args
    return this
  }

  page(pageNumber) {
    if (!pageNumber)
      pageNumber = 1

    this.page = pageNumber
    return this
  }

  ransack(params) {
    this.ransackOptions = Object.assign(this.ransackOptions, params)
    return this
  }

  result() {
    return new Promise((resolve, reject) => {
      this._response().then((response) => {
        var models = this._responseToModels(response)
        var result = new Result({
          "models": models,
          "response": response
        })
        resolve(result)
      })
    })
  }

  searchKey(searchKey) {
    this.searchKeyValue = searchKey
    return this
  }

  sort(sortBy) {
    this.ransackOptions["s"] = sortBy
    return this
  }

  toArray() {
    return new Promise((resolve, reject) => {
      this._response().then((response) => {
        var models = this._responseToModels(response)
        resolve(models)
      })
    })
  }

  modelClass() {
    return require(`ApiMaker/Models/${this.args.modelName}`).default
  }

  _response() {
    return new Promise((resolve, reject) => {
      var dataToUse = qs.stringify(this._params(), {"arrayFormat": "brackets"})
      var urlToUse = this.args.targetPathName + "?" + dataToUse

      var xhr = new XMLHttpRequest()
      xhr.open("GET", urlToUse)
      xhr.setRequestHeader("X-CSRF-Token", BaseModel._token())
      xhr.onload = () => {
        if (xhr.status == 200) {
          var response = JSON.parse(xhr.responseText)
          resolve(response)
        } else {
          reject({"responseText": xhr.responseText})
        }
      }
      xhr.send()
    })
  }

  _responseToModels(response) {
    var modelsResponseReader = new ModelsResponseReader({response: response})
    return modelsResponseReader.models()
  }

  _params() {
    var params = {}

    if (this.params)
      params = Object.assign(params, this.params)

    if (this.ransackOptions)
      params["q"] = this.ransackOptions

    if (this.limit)
      params["limit"] = this.limit

    if (this.includes)
      params["include"] = this.includes

    if (this.page)
      params["page"] = this.page

    return params
  }
}
