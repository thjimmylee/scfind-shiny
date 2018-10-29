FROM rocker/shiny:3.5.1

# install some R required stuff
RUN apt-get update -y --no-install-recommends \
    && apt-get -y install -f \
       zlib1g-dev \
       libssl-dev \
       libcurl4-openssl-dev \
       wget \
       && apt-get clean && \
       rm -rf /var/lib/apt/lists/*

# add app to the server
RUN mkdir -p indexes/mca/www/
RUN mkdir -p indexes/tm-10X/www/
RUN mkdir -p indexes/tm-facs/www/
# download indexes from google drive
# https://github.com/circulosmeos/gdown.pl
ADD gdown.pl /
RUN ./gdown.pl https://drive.google.com/file/d/1xz_ecGA0L85OzNf3Y2ifjYRyn3-H7q3X/view\?usp\=sharing indexes/mca/www/mca.rds
RUN ./gdown.pl https://drive.google.com/file/d/1YrvQSiX9mEzW2GulAo4tNOHre4h72sKW/view?usp=sharing indexes/tm-10X/www/mca.rds
RUN ./gdown.pl https://drive.google.com/file/d/11RwE2ZtojnQX4WyhXxKGtSkxQIlSJZx6/view?usp=sharing indexes/tm-facs/www/mca.rds
ADD app app/
RUN for d in indexes/*/; do cp app/* "$d"; done
RUN cp -r indexes/* /srv/shiny-server

# update the index page
COPY index_page/index.html /srv/shiny-server/index.html
COPY index_page/img /srv/shiny-server/img

# R packages
RUN install2.r data.table DT devtools ggplot2 hash

RUN echo 'source("https://bioconductor.org/biocLite.R")' > /opt/bioconductor.r && \
    echo 'biocLite()' >> /opt/bioconductor.r && \
    echo 'biocLite(c("SingleCellExperiment", "SummarizedExperiment"))' >> /opt/bioconductor.r && \
    Rscript /opt/bioconductor.r

RUN Rscript -e "devtools::install_github('hemberg-lab/scfind')"

# try to avoid greying out of the apps
# https://stackoverflow.com/questions/44397818/shiny-apps-greyed-out-nginx-proxy-over-ssl
RUN echo 'sanitize_errors off;disable_protocols xdr-streaming xhr-streaming iframe-eventsource iframe-htmlfile;' >> /etc/shiny-server/shiny-server.conf

CMD ["/usr/bin/shiny-server.sh"]
