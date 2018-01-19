module dub_up.github;

enum githubAPIURL = "https://api.github.com";

class Github {
    import std.format : format;
    import std.typecons : Tuple, tuple;

    import vibe.data.json;

    this(string user, string repo, string defaultBranch) {
        _user = user;
        _repo = repo;
        _defaultBranch = defaultBranch;
    }

    alias ResponseTuple = Tuple!(string, "response", string, "ETag");

    /** Send the provided string in a GET HTTP request.

        We return the response and the response's ETag. Providing the ETAG on
        later requests sends a conditional response. If the data is unchanged,
        the response field will be "304 Not Modified".

        It is assumed that if a conditional response is made, the caller already
        has the cached data.

        Params:
            req =   The JSON request to send.
            ETag =  An ETAG provided in a previous request.

        Returns:
            A Tuple of (response, ETag); the response is a JSON object and
            the ETag is the value of the returned ETag header.
    */
    ResponseTuple sendGetRequest(string req, string ETag = "") {
        ResponseTuple resp;
        resp = tuple("", "");
        return resp;
    }

    /** Retrieve the SHA for the tree of the specified branch.

        Params:
            branchName: The name of the branch for which to retrieve the SHA.

        Throws:
            Exception if the branch is not part of the repository.
    */
    string getBranchSHA(string branchName) {
        auto res = sendGetRequest("{}/repos/{}/{}/branches/{}"
                .format(githubAPIURL, _user, _repo));
        auto data = res.response.parseJsonString();
        if (branchName !in data) {
            throw new Exception("The branch is not present in the repository.");
        }
        return data[branchName]["sha"].get!string;
    }

    /** Return the list of files at the specified branches current commit
        in the format aa[filename] = SHA.
    */
    string[string] getFiles(string branch = _defaultBranch) {
        string[string] files;

        auto sha = getBranchSHA(branch);
        auto tree = sendGetRequest("{}/repos/{}/{}/git/trees/"
                .format(githubAPIURL, _user, _repo));

        auto data = parseJsonString(tree.response);
        foreach(item; data) {
            files[item["path"].get!string] = item["sha"].get!string;
        }
        return files;
    }

    bool hasFile(string filename, string branch = _defaultBranch) {
        return !!(filename in getFiles(branch));
    }

    string readFile(string filename) {
        import vibe.data.json;
        import std.base64 : Base64;
        import std.string : assumeUTF;

        // TODO: Because isValidUTF has an exception on failure internally and
        // I throw another here, this is inefficient, but flexible.
        // Not a long-term solution.
        // TODO: Send a PR for a better isValidUTF implementation to Phobos.
        auto files = getFiles("master");
        auto fileData = files[filename].parseJsonString;
        if (fileData["encoding"] != "base64")
            throw new Exception("Invalid encoding.");

        auto data = assumeUTF(Base64.decode(fileData["content"].get!string));
        if (data.isValidUTF) {
            return cast(string)data;
        } else throw new Exception("Input is invalid Unicode string.");
    }

    private:

    string _user;
    string _repo;
    string _defaultBranch;

    string[string] getRequestHeaders() {
        return [
            "Accept": "application/vnd.github.v3+json",
            "Authorization": "token {}" // TODO: auth token.
        ];
    }
}

// Validate with a nicer interface. utf.validate throws if it's
// invalid Unicode.
bool isValidUTF(const char[] str) {
    import std.utf : validate;
    scope(failure) return false;
    validate(str);
    return true;
}
