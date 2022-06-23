
# Start with a perfSONAR-flavored Unibuild

FROM ghcr.io/perfsonar/unibuild/alma9:latest

RUN mkdir -p /prep
COPY * /prep
RUN /prep/prep
RUN rm -rf /prep
