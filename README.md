# URLON in Nim

**URL Object Notation(URLON)** implemented in Nim.

URLON is originally designed by @vjeux (see [the blog](https://blog.vjeux.com/2011/javascript/urlon-url-object-notation.html)).
The main implementation is [here](https://github.com/cerebral/urlon).

## Run tests

```sh
nimble test
```

## Legacy URLON

Originally the prefix of URLON object is ``_``(underscore).
But now ``$``(dollar sign) is used for it.
The reason why it has changed is described [here](https://github.com/cerebral/urlon/releases/tag/3.0.0).

If you want to use the legacy version, try `-d:legacyUrlon` option.

## License

MIT  
&copy; 2022 Double-oxygeN
