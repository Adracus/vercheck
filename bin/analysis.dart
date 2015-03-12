library vercheck.analysis;

import 'dart:async' show Future;

import 'package:start/start.dart';
import 'package:vercheck/vercheck.dart';
import 'package:quiver/collection.dart';
import 'package:github/server.dart';

import 'auth.dart' as auth;
import 'cache.dart';
import 'images.dart';
import 'env.dart' as env;
import 'middleware.dart';
import 'db.dart' as db;


class SlugMapper {
  BiMap<RepositorySlug, int> _slugMapping = {};
  
  Future<int> slugToId(RepositorySlug slug) {
    if (_slugMapping.containsKey(slug)) return new Future.value(_slugMapping[slug]);
    return idFromSlug(slug, secret: env.secret, identifier: env.identifier).then((id) {
      return _slugMapping[slug] = id;
    });
  }
  
  Future<RepositorySlug> idToSlug(int id) {
    var inverse = _slugMapping.inverse;
    if (inverse.containsKey(id)) return new Future.value(inverse[id]);
    return slugFromId(id, secret: env.secret, identifier: env.identifier).then((slug) {
      return inverse[id] = slug;
    });
  }
}

final _slugMapper = new SlugMapper();


packageAnalysisError(Request request, e) {
  print(e);
  if (e is StatusException) {
    if (404 == e.response.statusCode)
      return request.response.status(404).send("Package not found");
  }
  return request.response.status(500).send("Internal server error");
}

Future<int> getRepoId(Request request, RepositorySlug slug) {
  var client = auth.getClient(request);
  return client.repositories.getRepository(slug).then((repo) {
    return repo.id;
  });
}

Future getAnalysis(Request request, RepositorySlug slug) {
  return _slugMapper.slugToId(slug).then((id) {
    var identifier = id.toString();
    return cache.containsKey(identifier).then((contained) {
      return cache.get(identifier).then((analysis) {
        if (null != analysis) return _renderAnalysis(request, analysis);
        
        return db.Repository.where({"id": id}).then((repos) {
          if (repos.isNotEmpty) {
            return createAnalysis(identifier, slug).then((analysis) {
              _renderAnalysis(request, analysis);
            });
          }
          return request.response.status(404).send("Not found");
        });
      });
    });
  });
}

postAnalysis(Request request) {
  if (!auth.isAuthorized(request))
    return authorize(request, redirectToCurrent: true);
  jsonBody(request).then((json) {
    if (null == json["user"] || null == json["repo"])
      return request.response.status(400).send("Fields are missing");
    var client = auth.getClient(request);
    client.users.getCurrentUser().then((user) {
      if (user.login.toLowerCase() != json["user"].toLowerCase())
        return request.response.status(401).send("Unauthorized");
      var slug = new RepositorySlug(json["user"], json["repo"]);
      
      return _slugMapper.slugToId(slug).then((id) {
        return db.Repository.where({"id": id}).then((repos) {
          var f;
          if (repos.isEmpty) {
            var repo = new db.Repository(id, user.id, slug.name);
            f = repo.save();
          }
          if (null == f) f = new Future.value();
          return f.then((_) {
            return createAnalysis(id.toString(), slug).then((analysis) {
              return request.response.status(201).json({"msg": "Created analysis"});
            });
          });
        });
      });
    });
  });
}

Future<Analysis> createAnalysis(String id, RepositorySlug slug) {
  return getGithubPackage(slug,
      secret: env.secret,
      identifier: env.identifier).then(Analysis.analyze).then((analysis) {
    return cache.put(id, analysis);
  });
}


_renderAnalysis(Request request, Analysis analysis) {
  var accept = request.header("accept");
  if (request.accepts("application/json"))
    return _renderJson(analysis, request);
  if (accept.any((part) => part.startsWith("image")))
    return _renderImage(analysis, request);
  return _renderHtml(analysis, request);
}

_renderHtml(Analysis analysis, Request request) {
  var path = request.path;
  return request.response
    ..status(200)
    ..header("content-type", "text/html")
    ..send('<img src="$path">');
}

_renderJson(Analysis analysis, Request request) {
  return request.response
    ..status(200)
    ..header("content-type", "application/json")
    ..json(analysis.toJsonRepresentation());
}

_renderImage(Analysis analysis, Request request) {
  var headers = {"content-type": "image/svg+xml"};
  request.response
    ..header("content-type", "image/svg+xml")
    ..status(200);
  if (analysis.isGood)
    return request.response.send(goodImage);
  if (analysis.isWarning)
    return request.response.send(warningImage);
  if (analysis.isBad)
    return request.response.send(badImage);
  return request.response.send(errorImage);
}
